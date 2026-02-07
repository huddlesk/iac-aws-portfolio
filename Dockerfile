FROM astral/uv:0.10-python3.13-alpine

# Install system dependencies
RUN apk add --no-cache openssh-client curl

# Install ansible using uv tool
# We include executables from ansible-core to ensure ansible-playbook is available
ENV PATH="/root/.local/bin:$PATH"
RUN uv tool install --with-executables-from ansible-core ansible
RUN uv tool install ansible-lint