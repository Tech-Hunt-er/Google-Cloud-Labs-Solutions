# Activity: Perform a SQL query

## Solution [here]()

### Run the following Commands

```
SELECT device_id, email_client
FROM machines;

SELECT device_id, operating_system, OS_patch_date
FROM machines;

SELECT event_id, country
FROM log_in_attempts
WHERE country = 'Australia';

SELECT username, login_date, login_time
FROM log_in_attempts
OFFSET 4 LIMIT 1;

SELECT *
FROM log_in_attempts;

SELECT *
FROM log_in_attempts
ORDER BY login_date;

SELECT * 
FROM log_in_attempts
ORDER BY login_date, login_time;
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*


# <img src="../logo.png" alt="Orbit of Ops Logo" width="45" align="center"> Orbit of Ops