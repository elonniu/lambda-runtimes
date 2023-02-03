# Load .env file if it exists
-include .env
export # export all variables defined in .env

export MAX_PARALLEL_PUBLISH ?= 8

env-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

build-devel-x86_64:
	CONTEXT_DIR=devel IMAGE=devel DOCKER_FILE=x86_64.prod.Dockerfile ARCH=x86_64 $(MAKE) build-image

build-devel-arm64:
	CONTEXT_DIR=devel IMAGE=devel DOCKER_FILE=arm64.prod.Dockerfile ARCH=arm64 $(MAKE) build-image

build-image: env-ARCH env-IMAGE env-TAG env-CONTEXT_DIR
	DOCKER_BUILDKIT=1 docker build --platform=linux/$(ARCH) -t public.ecr.aws/awsguru/$(IMAGE):$(TAG)-$(ARCH) ./$(CONTEXT_DIR) --file ./$(CONTEXT_DIR)/$(DOCKER_FILE)
	docker push public.ecr.aws/awsguru/$(IMAGE):$(TAG)-$(ARCH)

tag-manifest: env-ARCH env-IMAGE env-TAG
	docker pull public.ecr.aws/awsguru/$(IMAGE):$(TAG)-x86_64

	docker manifest create --amend public.ecr.aws/awsguru/$(IMAGE):$(TAG) \
				                   public.ecr.aws/awsguru/$(IMAGE):$(TAG)-arm64 \
				                   public.ecr.aws/awsguru/$(IMAGE):$(TAG)-x86_64

	docker manifest annotate --arch arm64 public.ecr.aws/awsguru/$(IMAGE):$(TAG) \
			                        	public.ecr.aws/awsguru/$(IMAGE):$(TAG)-arm64

	docker manifest push public.ecr.aws/awsguru/$(IMAGE):$(TAG)

layer-export-al2: env-ARCH env-IMAGE env-TAG env-CONTEXT_DIR
	DOCKER_BUILDKIT=1 docker build --platform=linux/$(ARCH) -t $(CONTEXT_DIR)-$(ARCH)-zip ./$(CONTEXT_DIR) --file ./$(CONTEXT_DIR)/layer.Dockerfile
	docker run -v /tmp/:/tmp/ --entrypoint /bin/mv $(CONTEXT_DIR)-$(ARCH)-zip /layer.zip /tmp/$(CONTEXT_DIR)-$(ARCH).zip
	LAYER=$(CONTEXT_DIR)-$(ARCH) AWS_DEFAULT_REGION=us-west-2 LAYER_NAME=bak-$(CONTEXT_DIR)-$(ARCH) ./publish_layer.sh
	#LAYER=$(CONTEXT_DIR)-$(ARCH) AWS_DEFAULT_REGION=ap-southeast-4 ./publish_layer.sh
	#LAYER=$(CONTEXT_DIR)-$(ARCH) $(MAKE) publish-parallel

publish-parallel:
	$(MAKE) -j${MAX_PARALLEL_PUBLISH} parallel-publish

parallel-publish: america-1 america-2 europe-1 europe-2 asia-1 asia-2 other

america-1:
	AWS_DEFAULT_REGION=us-east-1 ./publish_layer.sh #US East (Ohio)
	AWS_DEFAULT_REGION=us-east-2 ./publish_layer.sh #US East (Ohio)
	AWS_DEFAULT_REGION=us-west-1 ./publish_layer.sh #US West (N. California)

america-2:
	AWS_DEFAULT_REGION=us-west-2 ./publish_layer.sh #US West (Oregon)
	AWS_DEFAULT_REGION=ca-central-1 ./publish_layer.sh #Canada (Central)
	AWS_DEFAULT_REGION=sa-east-1 ./publish_layer.sh #South America (São Paulo)

europe-1:
	AWS_DEFAULT_REGION=eu-west-1 ./publish_layer.sh #Europe (Ireland)
	AWS_DEFAULT_REGION=eu-west-2 ./publish_layer.sh #Europe (London)
	AWS_DEFAULT_REGION=eu-west-3 ./publish_layer.sh #Europe (Paris)

europe-2:
	AWS_DEFAULT_REGION=eu-north-1 ./publish_layer.sh #Europe (Stockholm)
	AWS_DEFAULT_REGION=eu-south-1 ./publish_layer.sh #Europe (Milan)
	AWS_DEFAULT_REGION=eu-south-2 ./publish_layer.sh #Europe (Spain)
	AWS_DEFAULT_REGION=eu-central-1 ./publish_layer.sh #Europe (Frankfurt)
	AWS_DEFAULT_REGION=eu-central-2 ./publish_layer.sh #Europe (Zurich)

asia-1:
	AWS_DEFAULT_REGION=ap-east-1 ./publish_layer.sh #Asia Pacific (Hong Kong)
	AWS_DEFAULT_REGION=ap-south-1 ./publish_layer.sh #Asia Pacific (Mumbai)
	AWS_DEFAULT_REGION=ap-south-2 ./publish_layer.sh #Asia Pacific (Hyderabad)
	AWS_DEFAULT_REGION=ap-southeast-1 ./publish_layer.sh #Asia Pacific (Singapore)
	AWS_DEFAULT_REGION=ap-southeast-2 ./publish_layer.sh #Asia Pacific (Sydney)
	AWS_DEFAULT_REGION=ap-southeast-3 ./publish_layer.sh #Asia Pacific (Jakarta)
	AWS_DEFAULT_REGION=ap-southeast-4 ./publish_layer.sh #Asia Pacific (Melbourne)

asia-2:
	AWS_DEFAULT_REGION=ap-northeast-1 ./publish_layer.sh #Asia Pacific (Tokyo)
	AWS_DEFAULT_REGION=ap-northeast-2 ./publish_layer.sh #Asia Pacific (Seoul)
	AWS_DEFAULT_REGION=ap-northeast-3 ./publish_layer.sh #Asia Pacific (Osaka)

other:
	AWS_DEFAULT_REGION=af-south-1 ./publish_layer.sh #Africa (Cape Town)
	AWS_DEFAULT_REGION=me-south-1 ./publish_layer.sh #Middle East (Bahrain)
	AWS_DEFAULT_REGION=me-central-1 ./publish_layer.sh #Middle East (UAE)
	AWS_DEFAULT_REGION=ap-southeast-2 ./publish_layer.sh #Asia Pacific (Sydney)

nginx:
	docker-compose up devel-nginx \
					  prod-nginx
	docker-compose down

php:
	docker-compose up devel-php-74-fpm-nginx \
					  devel-php-80-fpm-nginx \
					  devel-php-81-fpm-nginx \
					  devel-php-82-fpm-nginx \
					  prod-php-74-fpm-nginx \
					  prod-php-80-fpm-nginx \
					  prod-php-81-fpm-nginx \
					  prod-php-82-fpm-nginx
	docker-compose down

php-beta:
	docker-compose up php-beta-fpm-nginx
	docker-compose down

clean:
	docker system prune -af
	docker image prune -f
	docker volume prune -f
	docker builder prune -f
