from fastapi import FastAPI
from retrofun.router import router

app = FastAPI()
app.include_router(router)
