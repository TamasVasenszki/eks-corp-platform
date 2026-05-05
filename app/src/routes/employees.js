const express = require("express");
const router = express.Router();
const pool = require("../db");
const authMiddleware = require("../middleware/auth");

router.use(authMiddleware);

router.get("/", async (req, res) => {
  const result = await pool.query("SELECT * FROM employees ORDER BY created_at DESC");
  res.json(result.rows);
});

router.get("/:id", async (req, res) => {
  const result = await pool.query("SELECT * FROM employees WHERE id = $1", [req.params.id]);
  if (!result.rows[0]) return res.status(404).json({ error: "Not found" });
  res.json(result.rows[0]);
});

router.post("/", async (req, res) => {
  const { name, email, department, position } = req.body;
  try {
    const result = await pool.query(
      "INSERT INTO employees (name, email, department, position) VALUES ($1, $2, $3, $4) RETURNING *",
      [name, email, department, position]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.put("/:id", async (req, res) => {
  const { name, email, department, position } = req.body;
  try {
    const result = await pool.query(
      "UPDATE employees SET name=$1, email=$2, department=$3, position=$4 WHERE id=$5 RETURNING *",
      [name, email, department, position, req.params.id]
    );
    if (!result.rows[0]) return res.status(404).json({ error: "Not found" });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete("/:id", async (req, res) => {
  const result = await pool.query("DELETE FROM employees WHERE id=$1 RETURNING *", [req.params.id]);
  if (!result.rows[0]) return res.status(404).json({ error: "Not found" });
  res.json({ message: "Deleted" });
});

module.exports = router;