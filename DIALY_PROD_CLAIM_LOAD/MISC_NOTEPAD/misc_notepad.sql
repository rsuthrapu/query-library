aws ssm start-session --region us-east-1 --target i-02d2b8762707706b6 --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="cig-cc-cdac-qa-01.cabfuldztvm4.us-east-1.rds.amazonaws.com",portNumber="53759",localPortNumber="53759" --profile qacdac


cdk deploy -c environment=qa GWCC-DMS-QACDA --profile qacdac

cdk synth -c environment=qa GWCC-DMS-QACDA --profile qacdac

cdk deploy -c environment=qa GWCC-EMR-QACDA --profile qacdac

cdk synth -c environment=qa GWCC-EMR-QACDA --profile qacdac

cdk deploy -c environment=qa GWCC-Prerequisites-QACDA --profile qacdac

cdk synth -c environment=qa GWCC-Prerequisites-QACDA --profile qacdac


aws ssm start-session --region us-east-1 --target i-055438c2818286e06 --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="cig-cc-cdac-stg-01.c2ujmfp1hyg2.us-east-1.rds.amazonaws.com",portNumber="53759",localPortNumber="53759" --profile stg-cdac




{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::088236692427:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow service-linked role use",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::088236692427:role/EMR_AutoScaling_DefaultRole",
                    "arn:aws:iam::088236692427:role/EMR_EC2_DefaultRole",
                    "arn:aws:iam::088236692427:role/EMR_DefaultRole",
                    "arn:aws:iam::088236692427:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
                ]
            },
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey",
                "kms:Encrypt",
                "kms:GenerateDataKey*",
                "kms:ReEncrypt*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow Autoscaling to create grant",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::088236692427:role/EMR_AutoScaling_DefaultRole",
                    "arn:aws:iam::088236692427:role/EMR_EC2_DefaultRole",
                    "arn:aws:iam::088236692427:role/EMR_DefaultRole",
                    "arn:aws:iam::088236692427:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
                ]
            },
            "Action": "kms:CreateGrant",
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        },
        {
            "Sid": "Account Access",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::088236692427:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "ec2",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "kms:*",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": "ec2.088236692427.amazonaws.com",
                    "kms:CallerAccount": "088236692427"
                }
            }
        },
        {
            "Sid": "Allow cloud9 service-linked role use",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::088236692427:role/aws-service-role/cloud9.amazonaws.com/AWSServiceRoleForAWSCloud9",
                    "arn:aws:iam::088236692427:role/EMR_AutoScaling_DefaultRole",
                    "arn:aws:iam::088236692427:role/EMR_EC2_DefaultRole",
                    "arn:aws:iam::088236692427:role/EMR_DefaultRole"
                ]
            },
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey",
                "kms:Encrypt",
                "kms:GenerateDataKey*",
                "kms:ReEncrypt*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow cloud9 attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::088236692427:role/aws-service-role/cloud9.amazonaws.com/AWSServiceRoleForAWSCloud9"
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        }
    ]
}



mvn install:install-file -Dfile=C:\Users\rsuthrapu\Downloads\ojdbc8-21.9.0.0.jar -DgroupId=com.oracle.jdbc -DartifactId=ojdbc8 -Dversion=21.9.0.0 -Dpackaging=jar -DgeneratePom=true


cdk synth -c environment=stg GWCC-DMS-STGCDA --profile stg-cdac

cdk deploy -c environment=stg GWCC-DMS-STGCDA --profile stg-cdac


cdk synth -c environment=stg GWCC-EMR-STGCDA --profile stg-cdac

cdk deploy -c environment=stg GWCC-EMR-STGCDA --profile stg-cdac


cdk synth -c environment=stg GWCC-Prerequisites-STGCDA --profile stg-cdac

cdk deploy -c environment=stg GWCC-Prerequisites-STGCDA --profile stg-cdac



aws ssm start-session --region us-east-1 --target i-055438c2818286e06 --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="cig-cc-cdac-stg-01.c2ujmfp1hyg2.us-east-1.rds.amazonaws.com",portNumber="53759",localPortNumber="53759" --profile stg-cdac

aws ssm start-session --region us-east-1 --target i-02d2b8762707706b6 --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="cig-cc-cdac-qa-01.cabfuldztvm4.us-east-1.rds.amazonaws.com",portNumber="53759",localPortNumber="53759" --profile qacdac

aws ssm start-session --region us-east-1 --target i-0030c52b4ad4560b7 --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="cig-cc-cdac-prd-01.cveb0j0yaoqf.us-east-1.rds.amazonaws.com",portNumber="53759",localPortNumber="53759" --profile prd-cdac



cdk synth -c environment=prd GWCC-Prerequisites-PRDCDA --profile prd-cdac

cdk deploy -c environment=prd GWCC-Prerequisites-PRDCDA --profile prd-cdac


cdk synth -c environment=prd GWCC-DMS-PRDCDA --profile prd-cdac

cdk deploy -c environment=prd GWCC-DMS-PRDCDA --profile prd-cdac


cdk synth -c environment=prd GWCC-EMR-PRDCDA --profile prd-cdac

cdk deploy -c environment=prd GWCC-EMR-PRDCDA --profile prd-cdac


aws ssm start-session --region us-east-1 --target i-02d2b8762707706b6 --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="cig-pc-cdac-qa-01.cabfuldztvm4.us-east-1.rds.amazonaws.com",portNumber="53759",localPortNumber="53759" --profile pcqacdac




GWCC-EMR-STGCDA-CheckCDAChangesBDDEED45-80CNjRQxhejt
GWCC-EMR-STGCDA-DBBackUpLambda4CE9467A-7hXzSbUmGjGI
GWCC-EMR-STGCDA-AuditControlsReportEBFC48EC-vwME4Y269Qnq
GWCC-EMR-STGCDA-CreateDBD6F2C9F2-6QDdhwqDjeWh
GWCC-EMR-STGCDA-RunAuditControlsCF0A9546-ePJozDQKFScB
GWCC-EMR-STGCDA-DBBackUpStatusLambdaB56ACD88-Bo5cP7ZKFlYW



				"arn:aws:events:us-east-1:670431693183:rule/GWCC-EMR-STGCDA",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-AuditControlsReportEBFC48EC-vwME4Y269Qnq",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-AuditControlsReportEBFC48EC-vwME4Y269Qnq:*",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-CheckCDAChangesBDDEED45-80CNjRQxhejt",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-CheckCDAChangesBDDEED45-80CNjRQxhejt:*",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-RunAuditControlsCF0A9546-ePJozDQKFScB",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-RunAuditControlsCF0A9546-ePJozDQKFScB:*",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-CreateDBD6F2C9F2-6QDdhwqDjeWh",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-CreateDBD6F2C9F2-6QDdhwqDjeWh:*",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-DBBackUpLambda4CE9467A-7hXzSbUmGjGI",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-DBBackUpLambda4CE9467A-7hXzSbUmGjGI:*",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-DBBackUpStatusLambdaB56ACD88-Bo5cP7ZKFlYW",
				"arn:aws:lambda:us-east-1:670431693183:function:GWCC-EMR-STGCDA-DBBackUpStatusLambdaB56ACD88-Bo5cP7ZKFlYW:*",
				
				
				
GWCC-EMR-PRDCDA-CreateDBD6F2C9F2-CceH0HvcjpSr
GWCC-EMR-PRDCDA-RunAuditControlsCF0A9546-0wu9LCkPcyXU
GWCC-EMR-PRDCDA-AuditControlsReportEBFC48EC-924QZt55bgUl
GWCC-EMR-PRDCDA-CheckCDAChangesBDDEED45-qx8p3HqJMWwK
GWCC-EMR-PRDCDA-DBBackUpStatusLambdaB56ACD88-ec2XQYWaZwcy
GWCC-EMR-PRDCDA-DBBackUpLambda4CE9467A-vbe8YVJb0Svv



GWPC-EMR-QACDA-RunAuditControlsCF0A9546-9ewXfZp9QGOO
GWPC-EMR-QACDA-AuditControlsReportEBFC48EC-l0m4sMaXFkmB
GWPC-EMR-QACDA-CheckCDAChangesBDDEED45-RKZYI93jN8cT
GWPC-EMR-QACDA-DBBackUpLambda4CE9467A-maqX3Ho2II6s
GWPC-EMR-QACDA-CreateDBD6F2C9F2-lhnnnaIsKk9H
GWPC-EMR-QACDA-DBBackUpStatusLambdaB56ACD88-8GTcGjzG7oUx

                "arn:aws:events:us-east-1:088236692427:rule/GWPC-EMR-QACDA",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-AuditControlsReportEBFC48EC-l0m4sMaXFkmB",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-AuditControlsReportEBFC48EC-l0m4sMaXFkmB:*",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-CheckCDAChangesBDDEED45-RKZYI93jN8cT",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-CheckCDAChangesBDDEED45-RKZYI93jN8cT:*",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-RunAuditControlsCF0A9546-9ewXfZp9QGOO",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-RunAuditControlsCF0A9546-9ewXfZp9QGOO:*",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-CreateDBD6F2C9F2-lhnnnaIsKk9H",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-CreateDBD6F2C9F2-lhnnnaIsKk9H:*",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-DBBackUpLambda4CE9467A-maqX3Ho2II6s",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-DBBackUpLambda4CE9467A-maqX3Ho2II6s:*",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-DBBackUpStatusLambdaB56ACD88-8GTcGjzG7oUx",
                "arn:aws:lambda:us-east-1:088236692427:function:GWPC-EMR-QACDA-DBBackUpStatusLambdaB56ACD88-8GTcGjzG7oUx:*",



{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "arn:aws:iam::*:role/aws-service-role/elasticmapreduce.amazonaws.com*/AWSServiceRoleForEMRCleanup*",
            "Condition": {
                "StringLike": {
                    "iam:AWSServiceName": [
                        "elasticmapreduce.amazonaws.com",
                        "elasticmapreduce.amazonaws.com.cn"
                    ]
                }
            }
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "rds:AddTagsToResource",
                "events:DescribeRule",
                "lambda:InvokeFunction",
                "rds:DescribeDBSnapshots",
                "events:PutRule",
                "elasticmapreduce:DescribeCluster",
                "dms:ReloadTables",
                "dms:DescribeReplicationTasks",
                "events:PutTargets",
                "iam:PassRole",
                "secretsmanager:GetSecretValue",
                "sns:Publish",
                "dms:StartReplicationTask",
                "rds:CreateDBSnapshot",
                "dms:StopReplicationTask",
                "dms:DescribeTableStatistics",
                "dms:CreateReplicationTask",
                "elasticmapreduce:TerminateJobFlows",
                "dms:RefreshSchemas",
                "kms:GenerateDataKey",
                "kms:Decrypt"
            ],
            "Resource": [
                "arn:aws:events:us-east-1:149170364662:rule/GWPC-EMR-DEVCDA",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-AuditControlsReportEBFC48EC-DrTzZhlSZxnx",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-AuditControlsReportEBFC48EC-DrTzZhlSZxnx:*",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-CheckCDAChangesBDDEED45-RvkCfMQhGHaG",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-CheckCDAChangesBDDEED45-RvkCfMQhGHaG:*",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-RunAuditControlsCF0A9546-9hDkaL1D6t5j",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-RunAuditControlsCF0A9546-9hDkaL1D6t5j:*",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-CreateDBD6F2C9F2-eRkIzRhvF3kA",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-CreateDBD6F2C9F2-eRkIzRhvF3kA:*",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-DBBackUpLambda4CE9467A-YOYEzPKb7qxD",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-DBBackUpLambda4CE9467A-YOYEzPKb7qxD:*",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-DBBackUpStatusLambdaB56ACD88-BXdJ4fWiqnwP",
                "arn:aws:lambda:us-east-1:149170364662:function:GWPC-EMR-DEVCDA-DBBackUpStatusLambdaB56ACD88-BXdJ4fWiqnwP:*",
                "arn:aws:elasticmapreduce:us-east-1:149170364662:cluster/*",
                "arn:aws:secretsmanager:*:149170364662:secret:*",
                "arn:aws:iam::149170364662:role/*",
                "arn:aws:sns:us-east-1:149170364662:*",
                "arn:aws:rds:*:149170364662:snapshot:*",
                "arn:aws:rds:*:149170364662:db:*",
                "arn:aws:dms:*:149170364662:rep:*",
                "arn:aws:dms:*:149170364662:endpoint:*",
                "arn:aws:dms:*:149170364662:task:*",
                "arn:aws:kms:us-east-1:149170364662:key/7631a17a-e749-4ae6-b2ff-b58a9f54dac3"
            ]
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "events:PutTargets",
                "iam:PassRole",
                "elasticmapreduce:DescribeStep",
                "events:DescribeRule",
                "events:PutRule",
                "elasticmapreduce:DescribeCluster",
                "elasticmapreduce:AddJobFlowSteps",
                "elasticmapreduce:CancelSteps"
            ],
            "Resource": [
                "arn:aws:iam::149170364662:role/EMR_AutoScaling_DefaultRole",
                "arn:aws:elasticmapreduce:us-east-1:149170364662:cluster/*",
                "arn:aws:events:us-east-1:149170364662:rule/GWPC-EMR-DEVCDA"
            ]
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "events:PutTargets",
                "events:DescribeRule",
                "events:PutRule",
                "iam:PutRolePolicy"
            ],
            "Resource": [
                "arn:aws:events:us-east-1:149170364662:rule/GWPC-EMR-DEVCDA",
                "arn:aws:iam::*:role/aws-service-role/elasticmapreduce.amazonaws.com*/AWSServiceRoleForEMRCleanup*"
            ]
        },
        {
            "Sid": "VisualEditor4",
            "Effect": "Allow",
            "Action": [
                "xray:PutTelemetryRecords",
                "logs:DescribeLogGroups",
                "rds:StartExportTask",
                "dms:DescribeReplicationTasks",
                "elasticmapreduce:DescribeCluster",
                "xray:GetSamplingTargets",
                "logs:GetLogDelivery",
                "logs:ListLogDeliveries",
                "xray:PutTraceSegments",
                "dms:CreateReplicationInstance",
                "logs:CreateLogDelivery",
                "logs:PutResourcePolicy",
                "dms:CreateEndpoint",
                "logs:UpdateLogDelivery",
                "xray:GetSamplingRules",
                "logs:DeleteLogDelivery",
                "elasticmapreduce:RunJobFlow",
                "logs:DescribeResourcePolicies",
                "elasticmapreduce:TerminateJobFlows"
            ],
            "Resource": "*"
        }
    ]
}

GWPC-EMR-PRDCDA-AuditControlsReportEBFC48EC-EsTZUhfODMvF
GWPC-EMR-PRDCDA-DBBackUpStatusLambdaB56ACD88-6YVjUyZPLhTF
GWPC-EMR-PRDCDA-RunAuditControlsCF0A9546-PbtWBQSmtS87
GWPC-EMR-PRDCDA-DBBackUpLambda4CE9467A-nQRr0W49qUtV
GWPC-EMR-PRDCDA-CreateDBD6F2C9F2-r17DOSNa0cWd
GWPC-EMR-PRDCDA-CheckCDAChangesBDDEED45-cNUblLWhkE00


                "arn:aws:events:us-east-1:129153805747:rule/GWPC-EMR-PRDCDA",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-AuditControlsReportEBFC48EC-EsTZUhfODMvF",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-AuditControlsReportEBFC48EC-EsTZUhfODMvF:*",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-CheckCDAChangesBDDEED45-cNUblLWhkE00",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-CheckCDAChangesBDDEED45-cNUblLWhkE00:*",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-RunAuditControlsCF0A9546-PbtWBQSmtS87",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-RunAuditControlsCF0A9546-PbtWBQSmtS87:*",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-CreateDBD6F2C9F2-r17DOSNa0cWd",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-CreateDBD6F2C9F2-r17DOSNa0cWd:*",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-DBBackUpLambda4CE9467A-nQRr0W49qUtV",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-DBBackUpLambda4CE9467A-nQRr0W49qUtV:*",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-DBBackUpStatusLambdaB56ACD88-6YVjUyZPLhTF",
                "arn:aws:lambda:us-east-1:129153805747:function:GWPC-EMR-PRDCDA-DBBackUpStatusLambdaB56ACD88-6YVjUyZPLhTF:*",

--------------------------------------------------------
--  DDL for Table CC_CATASTROPHE_TBL
--------------------------------------------------------

  CREATE TABLE "CCADMIN"."CC_CATASTROPHE_TBL" 
   (	"ACTIVE" NUMBER(1,0), 
	"BEANVERSION" NUMBER(10,0), 
	"BOTTOMRIGHTLATITUDE" NUMBER(38,5), 
	"BOTTOMRIGHTLONGITUDE" NUMBER(38,5), 
	"CATASTROPHENUMBER" VARCHAR2(1333 BYTE) COLLATE "USING_NLS_COMP", 
	"CATASTROPHEVALIDFROM" TIMESTAMP (6), 
	"CATASTROPHEVALIDTO" TIMESTAMP (6), 
	"COMMENTS" VARCHAR2(1333 BYTE) COLLATE "USING_NLS_COMP", 
	"CREATETIME" TIMESTAMP (6), 
	"CREATEUSERID" NUMBER(19,0), 
	"DESCRIPTION" VARCHAR2(1333 BYTE) COLLATE "USING_NLS_COMP", 
	"GWCBI___CONNECTOR_TS_MS" NUMBER(19,0), 
	"GWCBI___LSN" NUMBER(19,0), 
	"GWCBI___OPERATION" NUMBER(10,0), 
	"GWCBI___PAYLOAD_TS_MS" NUMBER(19,0), 
	"GWCBI___SEQVAL" NUMBER(38,0), 
	"GWCBI___SEQVAL_HEX" VARCHAR2(1333 BYTE) COLLATE "USING_NLS_COMP", 
	"GWCBI___TX_ID" NUMBER(19,0), 
	"GWCDAC__FINGERPRINTFOLDER" VARCHAR2(1333 BYTE) COLLATE "USING_NLS_COMP", 
	"GWCDAC__TIMESTAMPFOLDER" VARCHAR2(1333 BYTE) COLLATE "USING_NLS_COMP", 
	"ID" NUMBER(19,0), 
	"LOADCOMMANDID" NUMBER(19,0), 
	"NAME" VARCHAR2(1333 BYTE) COLLATE "USING_NLS_COMP", 
	"PCSCATASTROPHENUMBER" VARCHAR2(1333 BYTE) COLLATE "USING_NLS_COMP", 
	"POLICYEFFECTIVEDATE" TIMESTAMP (6), 
	"POLICYRETRIEVALCOMPLETIONTIME" TIMESTAMP (6), 
	"POLICYRETRIEVALSETTIME" TIMESTAMP (6), 
	"PUBLICID" VARCHAR2(1333 BYTE) COLLATE "USING_NLS_COMP", 
	"RETIRED" NUMBER(19,0), 
	"SCHEDULEBATCH" NUMBER(1,0), 
	"TOPLEFTLATITUDE" NUMBER(38,5), 
	"TOPLEFTLONGITUDE" NUMBER(38,5), 
	"TYPE" NUMBER(10,0), 
	"UPDATETIME" TIMESTAMP (6), 
	"UPDATEUSERID" NUMBER(19,0)
   )  DEFAULT COLLATION "USING_NLS_COMP" SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "CCDATA" ;


INSERT INTO
  COMMON_MRG.ECIG_DEPT_DETAILS_MAPPING (
    DEPT_NBR,
    DEPT_DESC,
    DESCRIPTION,
    CLASSCODE,
    EFFECTIVE_DATE,
    POLICY_PREFIX
  )
VALUES
  (
    62,
    'Restaurant',
    'Restaurant',
    19431,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    25,
    'Motel',
    'Hotel/Motel',
    69154,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    25,
    'Motel',
    'Hotel/Motel',
    69161,
    '21-NOV-23'
    'BOP'
  ),
  (
    62,
    'Restaurant',
    'Restaurant',
    19441,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    25,
    'Motel',
    'Hotel/Motel',
    69152,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    62,
    'Restaurant',
    'Restaurant',
    19651,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    62,
    'Restaurant',
    'Restaurant',
    19251,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    25,
    'Motel',
    'Hotel/Motel',
    69163,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    25,
    'Motel',
    'Hotel/Motel',
    69162,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    25,
    'Motel',
    'Hotel/Motel',
    69153,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    62,
    'Restaurant',
    'Restaurant',
    78409,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    62,
    'Restaurant',
    'Restaurant',
    19421,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    62,
    'Restaurant',
    'Restaurant',
    19661,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    62,
    'Restaurant',
    'Restaurant',
    19021,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    25,
    'Motel',
    'Hotel/Motel',
    69164,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    62,
    'Restaurant',
    'Restaurant',
    19111,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    62,
    'Restaurant',
    'Restaurant',
    19451,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    62,
    'Restaurant',
    'Restaurant',
    19001,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    62,
    'Restaurant',
    'Restaurant',
    19442,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  ),
  (
    25,
    'Motel',
    'Hotel/Motel',
    69151,
    TO_DATE('21-NOV-23', 'DD-MON-YY'),
    'BOP'
  );
COMMIT;


CREATE OR REPLACE VIEW DEPT_BUSINESS_LINE_FOR_PC AS
SELECT
  DISTINCT TO_NUMBER(V_DEPT_NBR) AS DEPT_NBR,
  V_DEPT_DESC AS DEPT_DESC,
  V_VALUE AS VALUE
FROM
  (
    SELECT
      CASE
        WHEN C.BUSINESS_LINE_NAME = 'Commercial Auto' THEN 71
        WHEN C.BUSINESS_LINE_NAME = 'Farm Auto' THEN 38
        WHEN C.BUSINESS_LINE_NAME = 'Business Owner' THEN D.DEPT_NBR
        WHEN C.BUSINESS_LINE_NAME = 'Commercial Umbrella' THEN 52
        ELSE 0
      END AS V_DEPT_NBR,
      CASE
        WHEN C.BUSINESS_LINE_NAME = 'Commercial Auto' THEN 'Commercial Auto'
        WHEN C.BUSINESS_LINE_NAME = 'Farm Auto' THEN 'Farm Auto'
        WHEN C.BUSINESS_LINE_NAME = 'Business Owner' THEN D.DEPT_DESC
        WHEN C.BUSINESS_LINE_NAME = 'Commercial Umbrella' THEN 'Commercial Excess Liability'
        ELSE 'Unknown'
      END AS V_DEPT_DESC,
      CASE
        WHEN C.BUSINESS_LINE_NAME = 'Commercial Auto' THEN 'Commercial Auto'
        WHEN C.BUSINESS_LINE_NAME = 'Farm Auto' THEN 'Farm Auto'
        WHEN C.BUSINESS_LINE_NAME = 'Business Owner' THEN D.VALUE
        WHEN C.BUSINESS_LINE_NAME = 'Commercial Umbrella' THEN 'Commercial Excess Liability'
        ELSE 'Unknown'
      END AS V_VALUE
    FROM
      COMMON_MRG.BUSINESS_LINE AS C
      LEFT JOIN (
        SELECT
          DISTINCT D.DEPT_NBR,
          D.DEPT_DESC,
          PV2.VALUE AS VALUE,
          "Business owner" BUSINESS_LINE_NAME
        FROM
          COMMON_MRG.bop_class_codes AS BCC,
          COMMON_MRG.bop_package_category AS BPC,
          COMMON_MRG.bop_package_type AS BPT,
          COMMON_MRG.param_values AS PV,
          COMMON_MRG.policy_prefix AS PP,
          COMMON_MRG.dept AS D,
          COMMON_MRG.param_values AS PV2,
          CMS_MRG.class_code_data AS CD
        WHERE
          PV.VALUE = CD.BP7CLASSCODE
          AND BCC.BOP_PACKAGE_CATEGORY = BPC.BOP_PACKAGE_CATEGORY
          AND BPC.BOP_PACKAGE_TYPE = BPT.BOP_PACKAGE_TYPE
          AND BCC.CLASS_CODE_NBR = PV.PARAM_VALUES
          AND BPT.TYPE = PV2.PARAM_VALUES
          AND BPC.DEPT = D.DEPT
          AND D.MAJOR_LINE = PP.MAJOR_LINE
          AND BCC.EFFECTIVE_DATE = (
            SELECT
              MAX(EFFECTIVE_DATE)
            FROM
              COMMON_MRG.bop_class_codes AS BCC2
            WHERE
              BCC2.CLASS_CODE_NBR = BCC.CLASS_CODE_NBR
              AND BCC2.BOP_PACKAGE_CATEGORY = BCC.BOP_PACKAGE_CATEGORY
          )
      ) AS D ON C.BUSINESS_LINE_NAME = D.BUSINESS_LINE_NAME
      ;
