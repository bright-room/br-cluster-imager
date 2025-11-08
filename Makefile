DEV_1PASSWORD_CREDENTIALS := $(shell cat ".secret/dev/1password-credentials.json" | base64)
DEV_1PASSWORD_CONNECT_TOKEN := $(shell cat ".secret/dev/.connect_token")
PROD_1PASSWORD_CREDENTIALS := $(shell cat ".secret/prod/1password-credentials.json" | base64)
PROD_1PASSWORD_CONNECT_TOKEN := $(shell cat ".secret/prod/.connect_token")

bootstrap:
	: > .env && \
	echo "OP_DEV_SESSION=$(DEV_1PASSWORD_CREDENTIALS)" >> .env && \
	echo "OP_DEV_CONNECT_TOKEN=$(DEV_1PASSWORD_CONNECT_TOKEN)" >> .env && \
	echo "OP_PROD_SESSION=$(PROD_1PASSWORD_CREDENTIALS)" >> .env && \
	echo "OP_PROD_CONNECT_TOKEN=$(PROD_1PASSWORD_CONNECT_TOKEN)" >> .env && \
	docker compose --profile bootstrap up -d

clean:
	docker compose --profile clean down -v && \
	rm -fr ./cloud-init/.generated && \
	rm -fr ./.generated && \
	rm -fr .env

####################################################################
#
# generate cloud config
#
####################################################################
generate-config: dev/generate-config prod/generate-config

dev/generate-config:
	docker compose --profile dev-generate-cloud-config build && \
	docker compose --profile dev-generate-cloud-config up

prod/generate-config:
	docker compose --profile prod-generate-cloud-config build && \
	docker compose --profile prod-generate-cloud-config up

####################################################################
#
# build image
#
####################################################################
# dev
dev/image-build:
	docker compose --profile dev-build-image up

dev/image-build/br-gateway1: .dev/image-build/gateway1
dev/image-build/br-gateway2: .dev/image-build/gateway2
dev/image-build/br-node1: .dev/image-build/node1
dev/image-build/br-node2: .dev/image-build/node2
dev/image-build/br-node3: .dev/image-build/node3
dev/image-build/br-node4: .dev/image-build/node4
dev/image-build/br-node5: .dev/image-build/node5
dev/image-build/br-node6: .dev/image-build/node6
dev/image-build/br-node7: .dev/image-build/node7
dev/image-build/br-node8: .dev/image-build/node8
dev/image-build/br-node9: .dev/image-build/node9
dev/image-build/br-node10: .dev/image-build/node10
dev/image-build/br-external1: .dev/image-build/external1
dev/image-build/br-external2: .dev/image-build/external2

.dev/image-build/%:
	docker compose --profile dev-build-image-$(@F) up

# prod
prod/image-build:
	docker compose --profile prod-build-image up

prod/image-build/br-gateway1: .prod/image-build/gateway1
prod/image-build/br-gateway2: .prod/image-build/gateway2
prod/image-build/br-node1: .prod/image-build/node1
prod/image-build/br-node2: .prod/image-build/node2
prod/image-build/br-node3: .prod/image-build/node3
prod/image-build/br-node4: .prod/image-build/node4
prod/image-build/br-node5: .prod/image-build/node5
prod/image-build/br-node6: .prod/image-build/node6
prod/image-build/br-node7: .prod/image-build/node7
prod/image-build/br-node8: .prod/image-build/node8
prod/image-build/br-node9: .prod/image-build/node9
prod/image-build/br-node10: .prod/image-build/node10
prod/image-build/br-external1: .prod/image-build/external1
prod/image-build/br-external2: .prod/image-build/external2

.prod/image-build/%:
	docker compose --profile prod-build-image-$(@F) up
