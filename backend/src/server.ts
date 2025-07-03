import { app } from './app';
import { connectDB } from './utils/db';

const PORT = process.env.PORT ? Number(process.env.PORT) : 4000;

(async () => {
  await connectDB();
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
})();
