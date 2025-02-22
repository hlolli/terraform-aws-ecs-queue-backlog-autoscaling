terraform {
  required_version = ">= 1.2"
}

# Create ECS service autoscaling policies
module "autoscale_service" {
  source = "./modules/service-autoscaling"

  cluster_name = var.cluster_name
  service_name = var.service_name
  queue_name   = var.queue_name

  max_capacity = var.service_max_capacity
  min_capacity = var.service_min_capacity

  target_value = var.queue_backlog_target_value

  queue_requires_consumer_alarm_tags = var.queue_requires_consumer_alarm_tags

  depends_on_service = var.depends_on_service
}

data "aws_lambda_function" "compute_queue_backlog" {
  function_name = var.lambda_name
}

# Create cloudwatch event resources to invoke the compute-queue-backlog lambda
resource "aws_cloudwatch_event_rule" "compute_queue_backlog" {
  name                = "${data.aws_lambda_function.compute_queue_backlog.function_name}-${var.service_name}"
  description         = "Schedule execution of ${data.aws_lambda_function.compute_queue_backlog.function_name} to compute queue backlog metrics for ${var.service_name} ${var.queue_name} queue."
  schedule_expression = var.lambda_invocation_interval

  tags = merge(
    {
      Name        = "${data.aws_lambda_function.compute_queue_backlog.function_name}-${var.service_name}"
      Description = "Schedule execution of ${data.aws_lambda_function.compute_queue_backlog.function_name} to compute queue backlog metrics for ${var.service_name} ${var.queue_name} queue."
    },
    var.cloudwatch_event_rule_tags
  )
}

resource "aws_cloudwatch_event_target" "compute_queue_backlog" {
  rule      = aws_cloudwatch_event_rule.compute_queue_backlog.name
  target_id = "${data.aws_lambda_function.compute_queue_backlog.function_name}-${var.service_name}"
  arn       = data.aws_lambda_function.compute_queue_backlog.arn
  input     = templatefile("${path.module}/files/cw_event_target_args.json.tpl", {
    cluster_name               = var.cluster_name
    service_name               = var.service_name
    metric_provider            = var.metric_provider
    metric_name                = var.metric_name
    metric_filter              = var.metric_filter
    metric_aggregate           = var.metric_aggregate
    queue_name                 = var.queue_name
    queue_owner_aws_account_id = var.queue_owner_aws_account_id != "" ? var.queue_owner_aws_account_id : data.aws_caller_identity.current.account_id
    est_msgs_per_sec           = var.service_est_msgs_per_sec
  })
}

resource "aws_lambda_permission" "compute_queue_backlog" {
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.compute_queue_backlog.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.compute_queue_backlog.arn
}

data "aws_caller_identity" "current" {}
