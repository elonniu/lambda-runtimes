# AWS Lambda Custom Layers

The goal of this repository is to support more and more programming languages.

### Supported Docker Images

| Custom Runtime | Version | Latest Docker Version                         |
|----------------|---------|-----------------------------------------------|
| Nginx          | 1.23    | public.ecr.aws/awsguru/nginx:1.23.2023.3.13.1 |
| PHP            | 8.2     | public.ecr.aws/awsguru/php:82.2023.3.13.1     |
| PHP            | 8.1     | public.ecr.aws/awsguru/php:81.2023.3.13.1     |
| PHP            | 8.0     | public.ecr.aws/awsguru/php:80.2023.3.13.1     |
| PHP            | 7.4     | public.ecr.aws/awsguru/php:74.2023.3.13.1     |

### Supported Zip Layers

| Custom Runtime | Version | Arch   | Latest Layer Version                                                 |
|----------------|---------|--------|----------------------------------------------------------------------|
| Nginx          | 1.23    | x86_64 | arn:aws:lambda:${AWS::Region}:753240598075:layer:Nginx123X86:12      |
| Nginx          | 1.23    | arm64  | arn:aws:lambda:${AWS::Region}:753240598075:layer:Nginx123Arm:12      |
| PHP            | 8.2     | x86_64 | arn:aws:lambda:${AWS::Region}:753240598075:layer:Php82FpmNginxX86:12 |
| PHP            | 8.2     | arm64  | arn:aws:lambda:${AWS::Region}:753240598075:layer:Php82FpmNginxArm:12 |
| PHP            | 8.1     | x86_64 | arn:aws:lambda:${AWS::Region}:753240598075:layer:Php81FpmNginxX86:12 |
| PHP            | 8.1     | arm64  | arn:aws:lambda:${AWS::Region}:753240598075:layer:Php81FpmNginxArm:12 |
| PHP            | 8.0     | x86_64 | arn:aws:lambda:${AWS::Region}:753240598075:layer:Php80FpmNginxX86:12 |
| PHP            | 8.0     | arm64  | arn:aws:lambda:${AWS::Region}:753240598075:layer:Php80FpmNginxArm:12 |
| PHP            | 7.4     | x86_64 | arn:aws:lambda:${AWS::Region}:753240598075:layer:Php74FpmNginxX86:12 |
| PHP            | 7.4     | arm64  | arn:aws:lambda:${AWS::Region}:753240598075:layer:Php74FpmNginxArm:12 |
