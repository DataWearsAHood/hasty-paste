# syntax=docker/dockerfile:1.4
ARG PYTHON_VERSION=3.12

FROM python:${PYTHON_VERSION}-alpine as build-deps

    WORKDIR /app

    WORKDIR /app

    COPY . .

    RUN python -m venv .venv
    ENV PATH="/app/.venv/bin:$PATH"

    RUN --mount=type=cache,target=/root/.cache pip install .

# reduce layers created in final image
FROM scratch as build-content

    WORKDIR /app

    COPY --from=build-deps --link /app/.venv .venv

    COPY paste_bin paste_bin

    COPY scripts/* ./

FROM python:${PYTHON_VERSION}-alpine

    # Fail on purpose
    RUN /bin/false

    WORKDIR /app

    EXPOSE 8000
    ENV PATH="/app/.venv/bin:$PATH"
    ENV STORAGE__DISK__PASTE_ROOT="/app/data"
    # Define .env vars with Default/error values
    #   expected to be squashed by Docker-compose/etc.
    ENV PASTE_ROOT=DF-UNDEFINED
    ENV TIME_ZONE=DF-UNDEFINED

    COPY --from=build-content --link /app /app

    # ensure that data folder gets created with nobody user
    RUN mkdir /app/data && chown -R nobody /app/data

    USER nobody:nobody

    ENTRYPOINT ["/bin/sh", "entrypoint.sh"]

    HEALTHCHECK --interval=1m --start-period=10s \
        CMD /bin/sh health-check.sh
