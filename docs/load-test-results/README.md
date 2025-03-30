# Load Test Results

Load tests were carried out using [Grafana K6](https://github.com/grafana/k6) to verify that the infrastructure can sustain 1000 RPS while maintaining <300ms latency in the Tokyo region.

## Test Conditions
- K6 was run on an EC2 instance located in Tokyo region (ap-northeast-1) to simulate requests generated in Tokyo.
- No AWS internal DNS names or private IPs were used to ensure the test accurately simulates public user traffic rather than optimized internal AWS networking.
- While the attached 'end_of_test_summary' files represent just two specific instances of the test, each type of test was conducted multiple times to ensure consistency.

## Load Test: 1000 RPS
Please refer to the [end of test summary file (1000rps)](end_of_test_summary_1000rps).
- **p(95) request duration:** ≈8ms  
- **Request success rate:** 100%

## Stress Test: 1500 RPS
Please refer to the [end of test summary file (1500rps)](end_of_test_summary_1500rps).
- **p(95) request duration:** ≈50ms  
- **Request success rate:** ≈99.999%

## Conclusion
The system handles 1000 RPS with headroom, as further demonstrated by the 1500 RPS test result. The request duration is also significantly below the target of 300ms, at an average of 8ms for 1000 RPS.
