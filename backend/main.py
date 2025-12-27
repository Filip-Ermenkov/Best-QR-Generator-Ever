import logging
import hashlib
import uuid
import os
import io
import boto3
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
import qrcode
from dotenv import load_dotenv

load_dotenv(dotenv_path="../.env")
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

s3_client = boto3.client(
    's3',
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    region_name=os.getenv("AWS_REGION")
)
S3_BUCKET = os.getenv("S3_BUCKET_NAME")

class QRRequest(BaseModel):
    url: HttpUrl

@app.post("/generate-qr/")
async def generate_qr(request: QRRequest):
    try:
        url_encoded = str(request.url).encode('utf-8')
        url_hash = hashlib.sha256(url_encoded).hexdigest()
        file_key = f"qrcodes/{url_hash}.png"

        try:
            s3_client.head_object(Bucket=S3_BUCKET, Key=file_key)
            logger.info(f"Existing QR found for: {request.url}")
        except:
            logger.info(f"Generating new QR for: {request.url}")
            qr = qrcode.QRCode(version=1, box_size=10, border=4)
            qr.add_data(str(request.url))
            qr.make(fit=True)
            img = qr.make_image(fill_color="#302e4d", back_color="white")
            
            img_buffer = io.BytesIO()
            img.save(img_buffer, format='PNG')
            img_buffer.seek(0)

            s3_client.upload_fileobj(
                img_buffer, 
                S3_BUCKET, 
                file_key,
                ExtraArgs={'ContentType': 'image/png'}
            )

        presigned_url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': S3_BUCKET, 'Key': file_key},
            ExpiresIn=3600
        )
        
        return {"qr_code_url": presigned_url}

    except Exception as e:
        logger.error(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal Server Error")