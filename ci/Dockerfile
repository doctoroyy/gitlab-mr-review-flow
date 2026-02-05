FROM oven/bun:latest as bun-base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install QMD globally
RUN bun install -g https://github.com/tobi/qmd

# Set up work directory
WORKDIR /app

# Copy scripts and CI tools
COPY scripts/ /app/scripts/
COPY ci/ /app/ci/

# Make scripts executable
RUN chmod +x /app/scripts/*.sh

# Install python dependencies for review_bot (scaffold)
# RUN pip3 install openai requests

CMD ["python3", "/app/ci/review_bot.py"]
