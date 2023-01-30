# Load .env file if it exists
-include .env
export # export all variables defined in .env

export MAX_PARALLEL_PUBLISH ?= 8
export ARCH ?= x86_64

env-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

release-nginx:
	TAG=nginx:1.23 $(MAKE) image-build-nginx-123
	$(MAKE) layer-export-nginx-123
	$(MAKE) layer-upload-nginx-123

release-php:
	TAG=php-82-fpm-nginx $(MAKE) image-build-php-82-fpm-nginx
	$(MAKE) layer-export-php-82-fpm-nginx
	$(MAKE) layer-upload-php-82-fpm-nginx

image-build-%: env-ARCH env-VERSION
	DOCKER_BUILDKIT=1 docker build --platform=$(PLATFORM) -t public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION)-$(ARCH) ./${*} --file ./${*}/$(FILE_PRE)$(ARCH).Dockerfile
	docker push public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION)-$(ARCH)

manifest-%: env-ARCH env-VERSION env-IMAGE
	# Current Version
	docker pull public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION)-x86_64
	docker pull public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION)-arm64

	docker manifest create --amend public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION) \
				                   public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION)-x86_64 \
				                   public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION)-arm64
	docker manifest annotate --arch arm64 public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION) \
			                        	public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION)-arm64
	docker manifest push public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION)

	# Main Latest Version
	docker manifest create public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)latest \
				           public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION)-x86_64 \
				           public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION)-arm64
	docker manifest annotate --arch arm64 public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)latest \
			                        	public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)$(VERSION)-arm64
	docker manifest push public.ecr.aws/awsguru/$(IMAGE):$(TAG_PRE)latest

layer-export-%: env-ARCH env-VERSION env-PLATFORM
	DOCKER_BUILDKIT=1 docker build --platform=$(PLATFORM) -t ${*}-$(ARCH)-zip ./${*} --file ./${*}/layer-$(ARCH).Dockerfile
	docker run -v /tmp/:/tmp/ --entrypoint /bin/mv ${*}-$(ARCH)-zip /layer.zip /tmp/${*}-$(ARCH).zip
	aws s3api put-object --bucket lambda-web-runtimes-layers --key $(VERSION)/${*}-$(ARCH).zip --body /tmp/${*}-$(ARCH).zip

layer-upload-%: env-ARCH env-VERSION
	#LAYER=${*}-$(ARCH) $(MAKE) publish-parallel

publish-parallel:
	$(MAKE) -j${MAX_PARALLEL_PUBLISH} parallel-publish

parallel-publish: america-1 america-2 europe-1 europe-2 asia-1 asia-2 miscellaneous

america-1:
	REGION=us-east-1 ./publish_layer.sh #US East (Ohio)
	REGION=us-east-2 ./publish_layer.sh #US East (Ohio)
	REGION=us-west-1 ./publish_layer.sh #US West (N. California)

america-2:
	REGION=us-west-2 ./publish_layer.sh #US West (Oregon)
	REGION=ca-central-1 ./publish_layer.sh #Canada (Central)
	REGION=sa-east-1 ./publish_layer.sh #South America (São Paulo)

europe-1:
	REGION=eu-west-1 ./publish_layer.sh #Europe (Ireland)
	REGION=eu-west-2 ./publish_layer.sh #Europe (London)
	REGION=eu-west-3 ./publish_layer.sh #Europe (Paris)

europe-2:
	REGION=eu-north-1 ./publish_layer.sh #Europe (Stockholm)
	REGION=eu-south-1 ./publish_layer.sh #Europe (Milan)
	REGION=eu-south-2 ./publish_layer.sh #Europe (Spain)
	REGION=eu-central-1 ./publish_layer.sh #Europe (Frankfurt)
	REGION=eu-central-2 ./publish_layer.sh #Europe (Zurich)

asia-1:
	REGION=ap-east-1 ./publish_layer.sh #Asia Pacific (Hong Kong)
	REGION=ap-south-1 ./publish_layer.sh #Asia Pacific (Mumbai)
	REGION=ap-south-2 ./publish_layer.sh #Asia Pacific (Hyderabad)
	REGION=ap-southeast-1 ./publish_layer.sh #Asia Pacific (Singapore)
	REGION=ap-southeast-2 ./publish_layer.sh #Asia Pacific (Sydney)
	REGION=ap-southeast-3 ./publish_layer.sh #Asia Pacific (Jakarta)

asia-2:
	REGION=ap-northeast-1 ./publish_layer.sh #Asia Pacific (Tokyo)
	REGION=ap-northeast-2 ./publish_layer.sh #Asia Pacific (Seoul)
	REGION=ap-northeast-3 ./publish_layer.sh #Asia Pacific (Osaka)

miscellaneous:
	REGION=af-south-1 ./publish_layer.sh #Africa (Cape Town)
	REGION=me-south-1 ./publish_layer.sh #Middle East (Bahrain)
	REGION=me-central-1 ./publish_layer.sh #Middle East (UAE)
	REGION=ap-southeast-2 ./publish_layer.sh #Asia Pacific (Sydney)

nginx:
	docker-compose up devel-nginx \
					  prod-nginx
	docker-compose down

php:
	docker-compose up devel-php-74-fpm-nginx \
					  devel-php-80-fpm-nginx \
					  devel-php-81-fpm-nginx \
					  devel-php-82-fpm-nginx \
					  beta-php-82-fpm-nginx \
					  prod-php-74-fpm-nginx \
					  prod-php-80-fpm-nginx \
					  prod-php-81-fpm-nginx \
					  prod-php-82-fpm-nginx
	docker-compose down

beta:
	docker-compose up beta-php-82-fpm-nginx
	docker-compose down

clean:
	docker system prune -af
	docker image prune -f
	docker volume prune -f
	docker builder prune -f
