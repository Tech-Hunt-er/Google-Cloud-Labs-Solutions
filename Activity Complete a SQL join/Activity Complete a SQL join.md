# Activity: Complete a SQL join

## Solution [here]()

### Run the following Commands

```
SELECT * 
FROM machines;

SELECT * 
FROM machines 
INNER JOIN employees ON machines.device_id = employees.device_id;

SELECT *
FROM machines
LEFT JOIN employees ON machines.device_id = employees.device_id;

SELECT *
FROM machines
RIGHT JOIN employees ON machines.device_id = employees.device_id;

SELECT * 
FROM employees 
INNER JOIN log_in_attempts ON employees.username = log_in_attempts.username;
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*


# <img src="../logo.png" alt="Tech Hunter Logo" width="45" align="center"> Tech Hunter