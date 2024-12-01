CREDENTIALS := $(shell cat ".secret/1password-credentials.json" | base64)
CONNECT_TOKEN := $(shell cat ".secret/.connect_token")

clean-all:
	docker compose --profile clean down -v && \
	rm -fr ./cloud-init/.generated && \
	rm -fr ./.generated && \
	rm -fr .env


pre-setup:
	touch .env && \
	echo "OP_PROD_SESSION=$(CREDENTIALS)" >> .env && \
	echo "OP_PROD_CONNECT_TOKEN=$(CONNECT_TOKEN)" >> .env && \
	docker compose --profile pre-setup up -d

generate-config:
	docker compose --profile generate-cloud-config build && \
	docker compose --profile generate-cloud-config up

image-build/prod/gateway1: .image-build/prod/gateway1
image-build/prod/node1: .image-build/prod/node1
image-build/prod/node2: .image-build/prod/node2
image-build/prod/node3: .image-build/prod/node3
image-build/prod/node4: .image-build/prod/node4
image-build/prod/node5: .image-build/prod/node5
image-build/prod/node6: .image-build/prod/node6
image-build/prod/external1: .image-build/prod/external1

.image-build/prod/%:
	docker compose --profile prod-build-image-$(@F) up
