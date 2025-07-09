from fastapi import APIRouter
import socket

router = APIRouter()

@router.get("/health")
def health_check():
    return {"status": "ok"}

@router.get("/api/message")
def get_message():
    hostname = socket.gethostname()
    return {
        "message": "Hello from Pratik Ghortale",
        "hostname": hostname
    }
    

