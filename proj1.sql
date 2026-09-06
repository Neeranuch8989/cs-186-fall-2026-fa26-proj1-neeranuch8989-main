-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era) AS
 SELECT MAX(era)
 FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT p.namefirst, p.namelast, p.birthyear
  FROM people p
  WHERE p.weight > 300;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT p.namefirst, p.namelast, p.birthyear
  FROM people p
   WHERE p.namefirst LIKE '% %'
  ORDER BY p.namefirst ASC, p.namelast ASC
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT p.birthyear, AVG(p.height), COUNT(*)
  FROM people p
  GROUP BY p.birthyear
  ORDER BY p.birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT p.birthyear, AVG(p.height), COUNT(*)
  FROM people p
  GROUP BY p.birthyear
  HAVING AVG(p.height) > 70
  ORDER BY p.birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT p.namefirst, p.namelast, h.playerid, h.yearid
  FROM halloffame h
  JOIN people p ON h.playerid = p.playerid
  WHERE h.inducted = 'Y'
  ORDER BY h.yearid DESC, h.playerid ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT p.namefirst, p.namelast, h.playerid, c.schoolid, h.yearid
  FROM halloffame h
  JOIN people p ON h.playerid = p.playerid
  JOIN collegeplaying c ON h.playerid = c.playerid
  JOIN schools s ON c.schoolid = s.schoolid
  WHERE h.inducted = 'Y'
    AND s.schoolstate = 'CA'
  ORDER BY h.yearid DESC, c.schoolid ASC, h.playerid ASC;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT h.playerid, p.namefirst, p.namelast, c.schoolid
  FROM halloffame h
  JOIN people p ON h.playerid = p.playerid
  LEFT JOIN collegeplaying c ON h.playerid = c.playerid
  WHERE h.inducted = 'Y'
  ORDER BY h.playerid DESC, c.schoolid ASC
;


-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT b.playerid, p.namefirst, p.namelast, b.yearid,
        (b.H + b.H2B + 2*b.H3B + 3*b.HR) * 1.0 / b.AB AS slg
  FROM batting b
  JOIN people p ON b.playerid = p.playerid
  WHERE b.AB > 50
  ORDER BY slg DESC, b.yearid ASC, b.playerid ASC
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT b.playerid, p.namefirst, p.namelast,
        ((SUM(b.H) + SUM(b.H2B) + 2*SUM(b.H3B) + 3*SUM(b.HR)) * 1.0 / SUM(b.AB)) AS lslg
  FROM batting b
  JOIN people p ON b.playerid = p.playerid
  GROUP BY b.playerid, p.namefirst, p.namelast
  HAVING SUM(b.AB) > 50
  ORDER BY lslg DESC, b.playerid ASC
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT p.namefirst, p.namelast,
        (SUM(b.H) + SUM(b.H2B) + 2*SUM(b.H3B) + 3*SUM(b.HR)) * 1.0 / SUM(b.AB) AS lslg
  FROM batting b
  JOIN people p ON b.playerid = p.playerid
  GROUP BY b.playerid, p.namefirst, p.namelast

  HAVING SUM(b.AB) > 50
    AND lslg > (
        SELECT (SUM(H) + SUM(H2B) + 2*SUM(H3B) + 3*SUM(HR)) * 1.0 / SUM(AB)
        FROM batting
        WHERE playerid = 'mayswi01')
  ORDER BY lslg DESC
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH stats AS (
      SELECT MIN(salary) AS min_salary,
            MAX(salary) AS max_salary
      FROM salaries
      WHERE yearid = 2016
  )

  SELECT b.binid,
        s.min_salary + b.binid * (s.max_salary - s.min_salary) / 10.0 AS low,
        s.min_salary + (b.binid + 1) * (s.max_salary - s.min_salary) / 10.0 AS high,
        COUNT(sa.salary) AS count
  FROM binids b
  CROSS JOIN stats s
  LEFT JOIN salaries sa
      ON sa.yearid = 2016
      AND ((sa.salary >= s.min_salary + b.binid * (s.max_salary - s.min_salary) / 10.0
          AND sa.salary < s.min_salary + (b.binid + 1) * (s.max_salary - s.min_salary) / 10.0)
          OR (b.binid = 9 AND sa.salary = s.max_salary)
      )
  GROUP BY b.binid
  ORDER BY b.binid ASC
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  WITH yearly AS (
      SELECT yearid, MIN(salary) AS min, MAX(salary) AS max, AVG(salary) AS avg, 
      LAG(MIN(salary)) OVER (ORDER BY yearid) AS prev_min, LAG(MAX(salary)) OVER (ORDER BY yearid) AS prev_max, LAG(AVG(salary)) OVER (ORDER BY yearid) AS prev_avg
      FROM salaries
      GROUP BY yearid
  )

  SELECT yearid, min - prev_min AS mindiff, max - prev_max AS maxdiff, avg - prev_avg AS avgdiff
  FROM yearly
  WHERE prev_min IS NOT NULL
  ORDER BY yearid ASC
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT s.playerid, p.namefirst, p.namelast, s.salary, s.yearid
  FROM salaries s
  JOIN people p ON s.playerid = p.playerid
  WHERE (s.yearid = 2000 AND s.salary = (SELECT MAX(salary) FROM salaries WHERE yearid = 2000))
    OR (s.yearid = 2001 AND s.salary = (SELECT MAX(salary) FROM salaries WHERE yearid = 2001))
  ORDER BY s.yearid ASC, s.playerid ASC

;

-- Question 4v
CREATE VIEW q4v(team, diffAvg) 
AS
  SELECT a.teamid, MAX(s.salary) - MIN(s.salary)
  FROM allstarfull a
  JOIN salaries s ON a.playerid = s.playerid
  WHERE a.yearid = 2016 AND s.yearid = 2016
  GROUP BY a.teamid
  ORDER BY a.teamid ASC;
;

