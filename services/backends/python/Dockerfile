FROM python:3.11-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY app.py /app/app.py
COPY gunicorn.conf.py /app/gunicorn.conf.py
COPY entrypoint.sh /app/entrypoint.sh

# Install Flask and Gunicorn
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir flask gunicorn debugpy

EXPOSE 8000

RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
