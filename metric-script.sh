#!/bin/bash

# Run the top command for 1 iteration and capture the output
top_output=$(top -b -n 1)

# Extract the top processes and their CPU usage
top_processes=$(echo "$top_output" | awk 'NR > 7 {print $1,$9}')

# Customize these variables:
namespace="Custom/MyApp"          # Namespace for your metrics
metric_name="MyCustomMetric"      # Name of the custom metric
dimension_name="InstanceName"     # Name of the dimension
dimension_value="WebServer"       # Value of the dimension
unit="Percent"                    # Unit of measurement for the metric
region="us-east-1"                # AWS region where metrics will be sent

# Loop through each line and publish the metrics to CloudWatch
while read -r line; do
    process_name=$(echo "$line" | awk '{print $1}')
    cpu_usage=$(echo "$line" | awk '{print $2}')

    # Publish the metric to CloudWatch
    aws cloudwatch put-metric-data \
        --namespace "$namespace" \
        --metric-name "$metric_name" \
        --dimensions "Name=$dimension_name,Value=$dimension_value" \
        --value "$cpu_usage" \
        --unit "$unit" \
        --region "$region"
done <<< "$top_processes"



#!/bin/bash

while true; do
    # Run the top command for 1 iteration and capture the output
    top_output=$(top -b -n 1)

    # Extract the top processes and their CPU usage
    top_processes=$(echo "$top_output" | awk 'NR > 7 {print $1,$9}')

    # Customize these variables:
    namespace="Custom/MyApp"          # Namespace for your metrics
    metric_name="MyCustomMetric"      # Name of the custom metric
    dimension_name="InstanceName"     # Name of the dimension
    dimension_value="WebServer"       # Value of the dimension
    unit="Percent"                    # Unit of measurement for the metric
    region="us-east-1"                # AWS region where metrics will be sent

    # Loop through each line and publish the metrics to CloudWatch
    while read -r line; do
        process_name=$(echo "$line" | awk '{print $1}')
        cpu_usage=$(echo "$line" | awk '{print $2}')

        # Publish the metric to CloudWatch
        aws cloudwatch put-metric-data \
            --namespace "$namespace" \
            --metric-name "$metric_name" \
            --dimensions "Name=$dimension_name,Value=$dimension_value" \
            --value "$cpu_usage" \
            --unit "$unit" \
            --region "$region"
    done <<< "$top_processes"

    # Sleep for 10 seconds before the next iteration
    sleep 10
done



