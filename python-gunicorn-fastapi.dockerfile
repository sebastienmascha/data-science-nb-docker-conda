FROM python:3.9

LABEL maintainer="Sebastien Mascha <sebastien.mascha@gmail.com>"

ARG YOUR_ENV=production
ARG INSTALL_JUPYTER=false

WORKDIR /app/

# Python configuration
ENV YOUR_ENV=${YOUR_ENV} \
  PYTHONFAULTHANDLER=1 \
  PYTHONUNBUFFERED=1 \
  PYTHONHASHSEED=random \
  PIP_NO_CACHE_DIR=off \
  PIP_DISABLE_PIP_VERSION_CHECK=on \
  PIP_DEFAULT_TIMEOUT=100 \
  POETRY_VERSION=1.1.5

# Poetry installation
RUN pip install "poetry==$POETRY_VERSION"

# Copy using poetry.lock* in case it doesn't exist yet
COPY ./app/pyproject.toml ./app/poetry.lock* /app/

# Python packages installation
RUN poetry config virtualenvs.create false \
  && poetry install $(test "$YOUR_ENV" == production && echo "--no-dev") --no-interaction --no-ansi

# For development, Jupyter remote kernel, Hydrogen
# Using inside the container:
# jupyter lab --ip=0.0.0.0 --allow-root --NotebookApp.custom_display_url=http://127.0.0.1:8888
RUN bash -c "if [ $INSTALL_JUPYTER == 'true' ] ; then poetry install jupyterlab ; fi"

# Starter scripts
COPY ./start.sh /start.sh
RUN chmod +x /start.sh

COPY ./gunicorn_conf.py /gunicorn_conf.py

COPY ./start-reload.sh /start-reload.sh
RUN chmod +x /start-reload.sh

COPY ./app /app

ENV PYTHONPATH=/app

# Run the start script, it will check for an /app/prestart.sh script (e.g. for migrations)
# And then will start Gunicorn with Uvicorn
CMD ["/start.sh"]
