import logging
import hashlib
import io
import os
from functools import lru_cache
from typing import Annotated

import boto3
import qrcode
from botocore.exceptions import ClientError
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Settings(BaseModel):
    aws_access_key_id: str | None = None
    aws_secret_access_key: str | None = None
    aws_region: str = "us-east-1"
    s3_bucket_name: str = "best-qr-ever-generated-codes"

@lru_cache()
def get_settings():
    return Settings(
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
        aws_region=os.getenv("AWS_REGION", "us-east-1"),
        s3_bucket_name=os.getenv("S3_BUCKET_NAME", "best-qr-ever-generated-codes")
    )

def get_s3_client(settings: Annotated[Settings, Depends(get_settings)]):
    client_kwargs = {'region_name': settings.aws_region}

    if settings.aws_access_key_id and settings.aws_secret_access_key:
        client_kwargs['aws_access_key_id'] = settings.aws_access_key_id
        client_kwargs['aws_secret_access_key'] = settings.aws_secret_access_key
        logger.info("Using Static AWS Credentials (Local/Manual)")
    else:
        logger.info("Using IAM Role / Pod Identity (Cloud Native)")
        
    return boto3.client('s3', **client_kwargs)

app = FastAPI(title="QR Generator API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class QRRequest(BaseModel):
    url: HttpUrl

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.post("/generate-qr/")
def generate_qr(
    request: QRRequest,
    s3_client = Depends(get_s3_client),
    settings: Settings = Depends(get_settings)
):
    url_str = str(request.url)
    url_hash = hashlib.sha256(url_str.encode('utf-8')).hexdigest()
    file_key = f"qrcodes/{url_hash}.png"

    try:
        try:
            s3_client.head_object(Bucket=settings.s3_bucket_name, Key=file_key)
            logger.info(f"Existing QR found for: {url_str}")
        except ClientError as e:
            if e.response['Error']['Code'] == "404":
                logger.info(f"Generating new QR for: {url_str}")

                qr = qrcode.QRCode(version=1, box_size=10, border=4)
                qr.add_data(url_str)
                qr.make(fit=True)
                img = qr.make_image(fill_color="#302e4d", back_color="white")
                
                img_buffer = io.BytesIO()
                img.save(img_buffer, format='PNG')
                img_buffer.seek(0)

                s3_client.upload_fileobj(
                    img_buffer, 
                    settings.s3_bucket_name, 
                    file_key,
                    ExtraArgs={'ContentType': 'image/png'}
                )
            else:
                raise e

        presigned_url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': settings.s3_bucket_name, 'Key': file_key},
            ExpiresIn=3600
        )
        
        return {"qr_code_url": presigned_url}

    except Exception as e:
        logger.error(f"Unexpected Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal Server Error")