#!/bin/bash


echo "Please enter cluster name"
read -p "Cluster Name: " cluster_name
export cluster_name=${cluster_name}

echo "Please enter Region name"
echo "Please keep region same as cluster region due to cross region cost"
read -p "Region Name: " region_name
export region_name=${region_name}

echo "#########"
echo "Enter bucket details"

echo "Please enter s3 Loki Chunk bucket name to create"
read -p "Bucket Name: " loki_chunk_bucket
# aws s3 mb "s3://${cluster_name}-${loki_chunk_bucket}" --region "${region_name}"
export env_loki_chunk_bucket="${cluster_name}-${loki_chunk_bucket}"
echo "Please enter s3 Loki Ruler bucket name to create"
read -p "Bucket Name: " loki_ruler_bucket
# aws s3 mb "s3://${cluster_name}-${loki_ruler_bucket}" --region "${region_name}"
export env_loki_ruler_bucket="${cluster_name}-${loki_ruler_bucket}"


echo "Please enter s3 Mimir Chunk bucket name to create"
read -p "Bucket Name: " mimir_chunk_bucket
# aws s3 mb "s3://${cluster_name}-${mimir_chunk_bucket}" --region "${region_name}"
export env_mimir_chunk_bucket="${cluster_name}-${mimir_chunk_bucket}"
echo "Please enter s3 Mimir Ruler bucket name to create"
read -p "Bucket Name: " mimir_ruler_bucket
# aws s3 mb "s3://${cluster_name}-${mimir_ruler_bucket}" --region "${region_name}"
export env_mimir_ruler_bucket="${cluster_name}-${mimir_ruler_bucket}"

echo "Please enter s3 Tempo Chunk bucket name to create"
read -p "Bucket Name: " tempo_chunk_bucket
# aws s3 mb "s3://${cluster_name}-${tempo_chunk_bucket}" --region "${region_name}"
export env_tempo_ruler_bucket="${cluster_name}-${tempo_chunk_bucket}"

echo "Please enter s3 Pyroscope Chunk bucket name to create"
read -p "Bucket Name: " pyroscope_chunk_bucket
# aws s3 mb "s3://${cluster_name}-${pyroscope_chunk_bucket}" --region "${region_name}"
export env_pyroscope_ruler_bucket="${cluster_name}-${pyroscope_chunk_bucket}"

#IAM POLICY creation
cat > ./loki/loki-s3-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "LokiStorage",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::${env_loki_chunk_bucket}",
                "arn:aws:s3:::${env_loki_chunk_bucket}/*",
                "arn:aws:s3:::${env_loki_ruler_bucket}",
                "arn:aws:s3:::${env_loki_ruler_bucket}/*"
            ]
        }
    ]
}
EOF
aws iam create-policy --policy-name LokiS3AccessPolicy --policy-document file://./loki/loki-s3-policy.json > /dev/null 2>&1

cat > ./mimir/mimir-s3-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "LokiStorage",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::${env_mimir_chunk_bucket}",
                "arn:aws:s3:::${env_mimir_chunk_bucket}/*",
                "arn:aws:s3:::${env_mimir_ruler_bucket}",
                "arn:aws:s3:::${env_mimir_ruler_bucket}/*"
        ]
    }
    ]
}
EOF
aws iam create-policy --policy-name MimirS3AccessPolicy --policy-document file://./mimir/mimir-s3-policy.json > /dev/null 2>&1

cat > ./tempo/tempo-s3-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "LokiStorage",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::${env_tempo_chunk_bucket}",
                "arn:aws:s3:::${env_tempo_chunk_bucket}/*"
        ]
    }
    ]
}
EOF
aws iam create-policy --policy-name TempoS3AccessPolicy --policy-document file://./tempo/tempo-s3-policy.json > /dev/null 2>&1

cat > ./pyroscope/pyroscope-s3-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "LokiStorage",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:ListBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::${env_pyroscope_chunk_bucket}",
                "arn:aws:s3:::${env_pyroscope_chunk_bucket}/*"
        ]
    }
    ]
}
EOF
aws iam create-policy --policy-name PyroscopeS3AccessPolicy --policy-document file://./pyroscope/pyroscope-s3-policy.json > /dev/null 2>&1

#IDP
export account_id=$(aws sts get-caller-identity --output json |jq -r '.Account')
export idp_id=$(aws eks describe-cluster --name ${cluster_name} --region ${region_name} --query 'cluster.identity.oidc.issuer' --output json|jq -r|awk -F'/' '{print $NF}')

cat > ./loki/loki-trust-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${account_id}:oidc-provider/oidc.eks.${region_name}.amazonaws.com/id/${idp_id}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.${region_name}.amazonaws.com/id/${idp_id}:aud": "sts.amazonaws.com",
                    "oidc.eks.${region_name}.amazonaws.com/id/${idp_id}:sub": "system:serviceaccount:loki:loki"
                }
            }
        }
    ]
}
EOF
aws iam create-role --role-name LokiServiceAccountRole --assume-role-policy-document file://./loki/loki-trust-policy.json > /dev/null 2>&1

cat > ./mimir/mimir-trust-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${account_id}:oidc-provider/oidc.eks.${region_name}.amazonaws.com/id/${idp_id}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.${region_name}.amazonaws.com/id/${idp_id}:aud": "sts.amazonaws.com",
                    "oidc.eks.${region_name}.amazonaws.com/id/${idp_id}:sub": "system:serviceaccount:mimir:mimir"
                }
            }
        }
    ]
}
EOF
aws iam create-role --role-name MimirServiceAccountRole --assume-role-policy-document file://./mimir/mimir-trust-policy.json > /dev/null 2>&1

cat > ./tempo/tempo-trust-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${account_id}:oidc-provider/oidc.eks.${region_name}.amazonaws.com/id/${idp_id}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.${region_name}.amazonaws.com/id/${idp_id}:aud": "sts.amazonaws.com",
                    "oidc.eks.${region_name}.amazonaws.com/id/${idp_id}:sub": "system:serviceaccount:tempo:tempo"
                }
            }
        }
    ]
}
EOF
aws iam create-role --role-name TempoServiceAccountRole --assume-role-policy-document file://./tempo/tempo-trust-policy.json > /dev/null 2>&1

cat > ./pyroscope/pyroscope-trust-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${account_id}:oidc-provider/oidc.eks.${region_name}.amazonaws.com/id/${idp_id}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.${region_name}.amazonaws.com/id/${idp_id}:aud": "sts.amazonaws.com",
                    "oidc.eks.${region_name}.amazonaws.com/id/${idp_id}:sub": "system:serviceaccount:loki:loki"
                }
            }
        }
    ]
}
EOF
aws iam create-role --role-name PyroscopeServiceAccountRole --assume-role-policy-document file://./pyroscope/pyroscope-trust-policy.json > /dev/null 2>&1

#Attach the policy to the role
aws iam attach-role-policy --role-name LokiServiceAccountRole --policy-arn arn:aws:iam::${account_id}:policy/LokiS3AccessPolicy > /dev/null 2>&1
aws iam attach-role-policy --role-name MimirServiceAccountRole --policy-arn arn:aws:iam::${account_id}:policy/MimirS3AccessPolicy > /dev/null 2>&1
aws iam attach-role-policy --role-name TempoServiceAccountRole --policy-arn arn:aws:iam::${account_id}:policy/TempoS3AccessPolicy > /dev/null 2>&1
aws iam attach-role-policy --role-name PyroscopeServiceAccountRole --policy-arn arn:aws:iam::${account_id}:policy/PyroscopeS3AccessPolicy > /dev/null 2>&1
