/*
🏥 Healthcare SQL Analysis Project

This project explores a simulated hospital database using SQL. It focuses on extracting actionable 
insights from multiple interrelated tables: patients, admissions, doctors, and province_names. 
The queries range from beginner-friendly aggregations to more advanced logic such as self-joins, 
conditional calculations, and pattern matching.


# Dataset Structure

- patients: Contains demographics, height, weight, and allergy information.

- admissions: Admission date, diagnosis, and attending doctor.

- doctors: Doctor profiles including specialty.

- province_names: Maps province_id to readable names.


🎯 Project Goals

- Practice and demonstrate SQL proficiency through a realistic healthcare use case.

- Analyze patient demographics and location distribution.

- Identify medical trends such as repeat diagnoses and obesity risk.

- Track doctor workloads and admission behaviors.
*/

-- 1. Count of male and female patients
SELECT 
  SUM(gender = 'M') AS male_count,
  SUM(gender = 'F') AS female_count 
FROM patients;


-- 2. Patients with repeat diagnoses
SELECT patient_id, diagnosis
FROM admissions
GROUP BY patient_id, diagnosis
HAVING COUNT(*) > 1;

-- 3. Number of patients by city
SELECT city, COUNT(*) AS num_patients
FROM patients
GROUP BY city
ORDER BY num_patients DESC, city ASC;

-- 4. Allergy counts
SELECT allergies, COUNT(*) AS total_diagnosis
FROM patients
WHERE allergies IS NOT NULL
GROUP BY allergies
ORDER BY total_diagnosis DESC;

-- 5. Patients born in the 1970s
SELECT first_name, last_name, birth_date
FROM patients
WHERE YEAR(birth_date) BETWEEN 1970 AND 1979
ORDER BY birth_date ASC;

-- 6. Provinces with total patient height above threshold
SELECT province_id, SUM(height) AS sum_height
FROM patients
GROUP BY province_id
HAVING sum_height >= 7000;

-- 7. Most active admission days
SELECT DAY(admission_date) AS day_number, COUNT(*) AS number_of_admissions
FROM admissions
GROUP BY day_number
ORDER BY number_of_admissions DESC;

-- 8. Most recent admission of a patient
SELECT * FROM admissions
WHERE patient_id = 542
GROUP BY patient_id
HAVING admission_date = MAX(admission_date);

-- 9. Complex filtering on doctors and patients
SELECT patient_id, attending_doctor_id, diagnosis
FROM admissions
WHERE (attending_doctor_id IN (1, 5, 19) AND patient_id % 2 != 0)
   OR (attending_doctor_id LIKE '%2%' AND LENGTH(patient_id) = 3);

-- 10. Admission count per doctor
SELECT first_name, last_name, COUNT(*)
FROM doctors p, admissions a
WHERE a.attending_doctor_id = p.doctor_id
GROUP BY p.doctor_id;

-- 11. Doctor’s first and last admission date
SELECT doctor_id, CONCAT(first_name, ' ', last_name) AS full_name,
       MIN(admission_date) AS first_admission_date,
       MAX(admission_date) AS last_admission_date
FROM admissions a
JOIN doctors ph ON a.attending_doctor_id = ph.doctor_id
GROUP BY doctor_id;

-- 12. Patient count by province name
SELECT province_name, COUNT(*) AS patient_count
FROM patients pa
JOIN province_names pr ON pr.province_id = pa.province_id
GROUP BY pr.province_id
ORDER BY patient_count DESC;

-- 13. Join patients, admissions and doctors
SELECT CONCAT(patients.first_name, ' ', patients.last_name) AS patient_name,
       diagnosis,
       CONCAT(doctors.first_name, ' ', doctors.last_name) AS doctor_name
FROM patients
JOIN admissions ON admissions.patient_id = patients.patient_id
JOIN doctors ON doctors.doctor_id = admissions.attending_doctor_id;

-- 14. Patients with duplicate names
SELECT first_name, last_name, COUNT(*) AS num_of_duplicates
FROM patients
GROUP BY first_name, last_name
HAVING COUNT(*) > 1;

-- 15. Convert height to feet and weight to pounds
SELECT CONCAT(first_name, ' ', last_name) AS patient_name,
       ROUND(height / 30.48, 1) AS height_feet,
       ROUND(weight * 2.205, 0) AS weight_pounds,
       birth_date,
       CASE WHEN gender = 'M' THEN 'MALE' ELSE 'FEMALE' END AS gender_type
FROM patients;

-- 16. Patients never admitted
SELECT patients.patient_id, first_name, last_name
FROM patients
LEFT JOIN admissions ON patients.patient_id = admissions.patient_id
WHERE admissions.patient_id IS NULL;

-- 17. Min, max, avg visits per day
SELECT MAX(number_of_visits) AS max_visits,
       MIN(number_of_visits) AS min_visits,
       ROUND(AVG(number_of_visits), 2) AS average_visits
FROM (
  SELECT admission_date, COUNT(*) AS number_of_visits
  FROM admissions
  GROUP BY admission_date
) AS subquery;

-- 18. Patients grouped by weight range
SELECT COUNT(*) AS patients_in_group,
       FLOOR(weight / 10) * 10 AS weight_group
FROM patients
GROUP BY weight_group
ORDER BY weight_group DESC;

-- 19. Obesity classification by BMI
SELECT patient_id, weight, height,
       CASE WHEN weight / POW(height / 100.0, 2) >= 30 THEN 1 ELSE 0 END AS isObese
FROM patients;

-- 20. Epilepsy patients of Dr. Lisa
SELECT p.patient_id, p.first_name AS patient_first_name,
       p.last_name AS patient_last_name, ph.specialty AS attending_doctor_specialty
FROM patients p
JOIN admissions a ON a.patient_id = p.patient_id
JOIN doctors ph ON ph.doctor_id = a.attending_doctor_id
WHERE ph.first_name = 'Lisa' AND a.diagnosis = 'Epilepsy';

-- 21. Temp password logic
SELECT DISTINCT p.patient_id,
       CONCAT(p.patient_id, LENGTH(last_name), YEAR(birth_date)) AS temp_password
FROM patients p
JOIN admissions a ON a.patient_id = p.patient_id;

-- 22. Insurance based cost estimate
SELECT has_insurance,
       CASE WHEN has_insurance = 'Yes' THEN COUNT(has_insurance) * 10
            ELSE COUNT(has_insurance) * 50 END AS cost_after_insurance
FROM (
  SELECT CASE WHEN patient_id % 2 = 0 THEN 'Yes' ELSE 'No' END AS has_insurance
  FROM admissions
) AS subquery
GROUP BY has_insurance;

-- 23. Provinces with more males than females
SELECT pr.province_name
FROM patients pa
JOIN province_names pr ON pa.province_id = pr.province_id
GROUP BY pr.province_name
HAVING SUM(gender = 'M') > SUM(gender = 'F');

-- 24. Multi-condition patient filter
SELECT *
FROM patients
WHERE first_name LIKE '__r%'
  AND gender = 'F'
  AND MONTH(birth_date) IN (2, 5, 12)
  AND weight BETWEEN 60 AND 80
  AND patient_id % 2 = 1
  AND city = 'Kingston';

-- 25. Male ratio in percentage
SELECT CONCAT(ROUND(SUM(gender = 'M') / COUNT(*) * 100, 2), '%') AS male_ratio
FROM patients;

-- 26. Daily change in admissions
SELECT admission_date,
       COUNT(admission_date) AS admission_day,
       COUNT(admission_date) - LAG(COUNT(admission_date)) OVER(ORDER BY admission_date) AS admission_count_change
FROM admissions
GROUP BY admission_date;

-- 27. Ontario province first
SELECT province_name
FROM province_names
ORDER BY province_name = 'Ontario' DESC, province_name;
