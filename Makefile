IMAGE_LAMBDA_GO=eawsy/aws-lambda-go-shim

GOPATH ?= $(HOME)/go
HANDLER ?= handler
PACKAGE ?= package

aws-all: clean dist aws-deploy
.PHONY: aws-all

sls-all: clean dist sls-deploy
.PHONY: sls-all

deps:
	go get -u -d github.com/eawsy/aws-lambda-go-core/...
	docker pull eawsy/aws-lambda-go-shim
.PHONY: deps

clean: _clean
.PHONY: clean

dist:
	@docker run --rm \
		-v "$(GOPATH)":/go -v "$(shell PWD)":/tmp \
		-e "HANDLER=$(HANDLER)" -e "PACKAGE=$(PACKAGE)" \
		eawsy/aws-lambda-go-shim make _dist
.PHONY: dist

# debug shell when things go unexpected
shell:
	@docker run --rm -ti \
		-v "$(GOPATH)":/go -v "$(shell PWD)":/tmp \
		-e "HANDLER=$(HANDLER)" -e "PACKAGE=$(PACKAGE)" \
		eawsy/aws-lambda-go-shim bash
.PHONY: shell

# aws cli deploy
aws-deploy:
	@echo -ne "deploying lambda..."\\n
	aws lambda create-function \
	  --role arn:aws:iam::$(AWS_ACCOUNT_NUMBER):role/lambda_basic_execution \
	  --function-name preview-go \
	  --zip-file fileb://package.zip \
	  --runtime python2.7 \
	  --handler handler.Handle
	@echo -ne "done!"\\n
.PHONY: deploy

aws-invoke:
	aws lambda invoke --function-name preview-go out.txt

aws-delete:
	@echo -ne "deleting lambda..."\\n
	aws lambda delete-function --function-name preview-go
	@echo -ne "done!"\\n
.PHONY: deploy

# serverless targets
sls-deploy:
	sls deploy
.PHONY: sls-deploy

sls-invoke:
	sls invoke -f hello
.PHONY: sls-invoke

sls-delete:
	sls remove -v
.PHONY: sls-delete

# make targets inside docker container
_dist: _clean _build _pack _inject
	@chown $(shell stat -c '%u:%g' .) $(PACKAGE).zip
	@echo -ne "build, pack, inject, go!"\\n

_clean:
	@rm -rf $(PACKAGE).zip $(HANDLER).so

_build:
	@echo -ne "build..."\\r
	@go build -buildmode=plugin -ldflags='-w -s' -o $(HANDLER).so
	@chown $(shell stat -c '%u:%g' .) $(HANDLER).so

_pack:
	@echo -ne "build, pack"\\r
	@zip -q $(PACKAGE).zip $(HANDLER).so

_inject:
	@echo -ne "build, pack, inject"\\r
	@cd /; mv /shim $(HANDLER); zip -q -r /tmp/$(PACKAGE).zip $(HANDLER)

