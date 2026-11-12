FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY office_app.py /app/office_app.py

EXPOSE 8000

CMD ["python3", "office_app.py"]
