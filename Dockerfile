FROM nvidia/cuda:11.7.1-runtime-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LANG=C.UTF-8

RUN set -x && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -qq -y git build-essential python3-dev python-is-python3 ca-certificates curl python3-pip python3-venv libtcmalloc-minimal4 && \
    #apt-get install --no-install-recommends -qq -y ffmpeg libopencv-dev && \
    rm -rf /var/lib/apt/lists/*

#ENV LD_PRELOAD=libtcmalloc.so

RUN set -x && \
    git clone  https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /app
    #mkdir -p /app && \
    #curl -sSL https://github.com/AUTOMATIC1111/stable-diffusion-webui/archive/refs/heads/master.tar.gz | tar -xzC /app --strip-components=1 && \
    #mkdir -p /app/.git

ADD ./gitconfig /app/.gitconfig

RUN useradd -m -s /bin/bash --home-dir /app appuser  && \
    mkdir -p /out && \
    chown -R appuser:appuser /app /out

ADD ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

RUN set -x && \
    apt-get -qq update && \
    apt-get install -qq -y openssh-server tmux --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

RUN echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config && \
    mkdir /var/run/sshd && \
    echo "root:root" | chpasswd


USER appuser

RUN set -x && \
    python -m venv /app/venv && \
    /app/venv/bin/pip install -r /app/requirements.txt

ENV TORCH_COMMAND "/app/venv/bin/pip install torch --index-url https://download.pytorch.org/whl/cu118"

RUN bash -c "${TORCH_COMMAND}"

WORKDIR /app

RUN set -x && \
    # models/Stable-diffusion
    rm -rf models/Stable-diffusion && \
    mkdir -p /out/sd/models/Stable-diffusion && \
    ln -s /out/sd/models/Stable-diffusion models/Stable-diffusion && \
    # models/Lora
    mkdir -p /out/sd/models/Lora && \
    ln -s /out/sd/models/Lora models/Lora && \
    # models/VAE
    rm -rf models/VAE && \
    mkdir -p /out/sd/models/VAE && \
    ln -s /out/sd/models/VAE models/VAE && \
    # models/ESRGAN
    rm -rf models/ESRGAN && \
    mkdir -p /out/sd/models/ESRGAN && \
    ln -s /out/sd/models/ESRGAN models/ESRGAN && \
    # embeddings
    rm -rf embeddings && \
    mkdir -p /out/sd/embeddings && \
    ln -s /out/sd/embeddings embeddings && \
    # extensions/sd-webui-controlnet
    mkdir -p extensions/sd-webui-controlnet && \
    curl -sSL https://github.com/Mikubill/sd-webui-controlnet/archive/refs/heads/main.tar.gz \
        | tar -xzC extensions/sd-webui-controlnet --strip-components=1 && \
    # extensions/adetailer
    mkdir -p extensions/adetailer && \
    curl -sSL https://github.com/Bing-su/adetailer/archive/refs/heads/main.tar.gz \
        | tar -xzC extensions/adetailer --strip-components=1 && \
    # extensions/sd-webui-refiner
    mkdir -p extensions/sd-webui-refiner && \
    curl -sSL https://github.com/wcde/sd-webui-refiner/archive/refs/heads/main.tar.gz \
        | tar -xzC extensions/sd-webui-refiner --strip-components=1 && \
    # extensions/sd_civitai_extension
    mkdir -p extensions/sd_civitai_extension && \
    curl -sSL https://github.com/civitai/sd_civitai_extension/archive/refs/heads/main.tar.gz \
        | tar -xzC extensions/sd_civitai_extension --strip-components=1 && \
    # ultimate-upscale-for-automatic1111
    mkdir -p extensions/ultimate-upscale-for-automatic1111 && \
    curl -sSL https://github.com/Coyote-A/ultimate-upscale-for-automatic1111/archive/refs/heads/master.tar.gz \
        | tar -xzC extensions/ultimate-upscale-for-automatic1111 --strip-components=1


ENV STABLE_DIFFUSION_COMMIT_HASH="cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf"
RUN git clone https://github.com/Stability-AI/stablediffusion.git /app/repositories/stable-diffusion-stability-ai && \
    git -C /app/repositories/stable-diffusion-stability-ai checkout "$STABLE_DIFFUSION_COMMIT_HASH"

ENV STABLE_DIFFUSION_XL_COMMIT_HASH="5c10deee76adad0032b412294130090932317a87"
RUN git clone https://github.com/Stability-AI/generative-models.git /app/repositories/generative-models && \
    git -C /app/repositories/generative-models checkout "$STABLE_DIFFUSION_XL_COMMIT_HASH"

ENV CODEFORMER_COMMIT_HASH="c5b4593074ba6214284d6acd5f1719b6c5d739af"
RUN git clone https://github.com/sczhou/CodeFormer.git /app/repositories/CodeFormer && \
    git -C /app/repositories/CodeFormer checkout "$CODEFORMER_COMMIT_HASH"

ENV K_DIFFUSION_COMMIT_HASH="c9fe758757e022f05ca5a53fa8fac28889e4f1cf"
RUN git clone https://github.com/crowsonkb/k-diffusion.git /app/repositories/k-diffusion && \
    git -C /app/repositories/k-diffusion checkout "$K_DIFFUSION_COMMIT_HASH"

ENV BLIP_COMMIT_HASH="48211a1594f1321b00f14c9f7a5b4813144b2fb9"
RUN git clone https://github.com/salesforce/BLIP.git repositories/BLIP && \
    git -C /app/repositories/BLIP checkout "$BLIP_COMMIT_HASH"

USER root

RUN mkdir -p /app/.cache/huggingface/accelerate/ && chown -R appuser:appuser /app/.cache
ADD ./accellerate-default_config.yaml /app/.cache/huggingface/accelerate/default_config.yaml
# libglib2.0-dev
RUN set -x && apt-get -qq update && apt-get install -y libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

STOPSIGNAL SIGINT

EXPOSE 22
EXPOSE 7860

ENV ACCELERATE=True

VOLUME [ "/out" ]

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]