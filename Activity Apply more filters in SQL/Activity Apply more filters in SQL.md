# Activity: Apply more filters in SQL

## Solution [here]()

### Run the following Commands

```
SELECT * 
FROM log_in_attempts 
WHERE login_date > '2022-05-09';

SELECT * 
FROM log_in_attempts 
WHERE login_date >= '2022-05-09';

SELECT * 
FROM log_in_attempts 
WHERE login_date BETWEEN '2022-05-09' AND '2022-05-11';

SELECT * 
FROM log_in_attempts 
WHERE login_time < '07:00:00';

SELECT * 
FROM log_in_attempts 
WHERE login_time >= '06:00:00' AND login_time < '07:00:00';

SELECT event_id, username, login_date
FROM log_in_attempts
WHERE event_id >= 100;

SELECT event_id, username, login_date
FROM log_in_attempts
WHERE event_id BETWEEN 100 AND 150;
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*


# <img src="../logo.png" alt="Orbit of Ops Logo" width="45" align="center"> Orbit of Ops