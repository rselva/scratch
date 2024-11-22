locals {
  name_prefix = "coastal"
}
module "cloudwatch" {
  source = "../modules/cloudwatch-logs-group"

  name_prefix = "/aws/events/carrier-partitions-bucket"
}

module "s3_bucket_usage" {
  source = "../modules/bucket-with-retention-v2"

  name_prefix = "carrier-partitions"

  # notifications = [
  #   {
  #     name = "bucket-events"
  #     events = [
  #       "s3:ObjectCreated:*",
  #       "s3:ObjectRemoved:*"
  #     ]
  #     filter_prefix = "ccif"
  #     filter_suffix = "csv"
  #   }
  # ]

  retention = {
    expiration = 0    # no expire
    glacier    = 3700 # after 10 years
  }

  eventbridge = {
    enabled    = true
    cloudwatch = module.cloudwatch
  }
}

module "glue_crawler_carrier_partitions" {
  source = "../modules/glue-bucket-crawler-v2"

  name_prefix = local.name_prefix
  name        = "carrier-partitions"
  database    = "coastal"

  classifiers = [
    aws_glue_classifier.carrier_partitions.name
  ]

  configuration = jsonencode(
    {
      Grouping = {
        TableGroupingPolicy = "CombineCompatibleSchemas"

      }
      CrawlerOutput = {
        Tables = {
          TableThreshold = 1
        }
        Partitions = {
          AddOrUpdateBehavior = "InheritFromTable"
        }
      }
      CreatePartitionIndex = true
      Version              = 1

    }
  )

  target = {
    bucket     = "slv-coastal-aws-132322874863-us-east-1"
    path       = "carrier_partitions"
    exclusions = ["**/*.metadata"]
  }
}

resource "aws_glue_catalog_table" "carrier_partitions" {
  database_name = "coastal"
  name          = "carrier_partitions"

  parameters = {
    exclusions = jsonencode(
      ["**/*.metadata"]
    )
    "skip.header.line.count" = "1"
    classification           = "csv"
    columnsOrdered           = "true"
    compressionType          = "none"
    delimiter                = ","
    typeOfData               = "file"
  }
  table_type = "EXTERNAL_TABLE"

  partition_keys {
    name = "day"
    type = "string"
  }
  partition_keys {
    name = "guid"
    type = "string"
  }
  partition_keys {
    name = "carrier"
    type = "string"
  }
  storage_descriptor {
    location      = "s3://slv-coastal-aws-132322874863-us-east-1/carrier_partitions/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "separatorChar" = ","
        "quoteChar"     = "\""
      }
    }
    columns {
      name = "start_at"
      type = "string"
    }
    columns {
      name = "end_at"
      type = "string"
    }
    columns {
      name = "traffic_id"
      type = "string"
    }
    columns {
      name = "fl_mb"
      type = "string"
    }
    columns {
      name = "rl_mb"
      type = "string"
    }
    columns {
      name = "total"
      type = "string"
    }
    columns {
      name = "service_code"
      type = "string"
    }
    columns {
      name = "beam"
      type = "string"
    }
    columns {
      name = "network"
      type = "string"
    }
    columns {
      name = "jurisdictional_region"
      type = "string"
    }
    columns {
      name = "units"
      type = "string"
    }
    columns {
      name = "flex"
      type = "string"
    }
  }
}

resource "aws_glue_classifier" "carrier_partitions" {
  name = "${local.name_prefix}-carrier-partitions"

  csv_classifier {
    allow_single_column        = false
    disable_value_trimming     = false
    delimiter                  = ","
    quote_symbol               = "\""
    contains_header            = "PRESENT"
    custom_datatype_configured = true

    header = [
      "start_at",
      "end_at",
      "traffic_id",
      "fl_mb",
      "rl_mb",
      "total",
      "service_code",
      "beam",
      "network",
      "jurisdictional_region",
      "units",
      "flex"
    ]
    custom_datatypes = [
      "STRING",
      "STRING",
      "STRING",
      "STRING",
      "STRING",
      "STRING",
      "STRING",
      "STRING",
      "STRING",
      "STRING",
      "STRING",
      "STRING"
    ]
  }
}
