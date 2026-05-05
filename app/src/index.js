const express = require("express");
const app = express();

app.use(express.json());

app.use("/health", require("./routes/health"));
app.use("/auth", require("./routes/auth"));
app.use("/employees", require("./routes/employees"));
app.use("/documents", require("./routes/documents"));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));