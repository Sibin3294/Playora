import { connectDb } from './config/db';
import { createApp } from './app';
import { hydrateCatalogFromMongo } from './services/catalog.service';

const port = Number(process.env.PORT || 3100);

async function main(): Promise<void> {
  let mongoStatus = 'unavailable';
  try {
    mongoStatus = await connectDb();
    await hydrateCatalogFromMongo();
  } catch (error) {
    // Catalog routes still work from JSON seeds; gameplay DB routes need Mongo.
    console.error('MongoDB unavailable — catalog APIs still online.', error);
  }
  const app = createApp();
  app.listen(port, '0.0.0.0', () => {
    console.log(`Number Hunter API on http://0.0.0.0:${port}`);
    console.log(`Phone / LAN clients: http://<this-mac-ip>:${port}`);
    console.log(`MongoDB ${mongoStatus}`);
    console.log('Catalog: GET /api/catalog');
    console.log('Admin:   POST /api/admin/login');
  });
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
