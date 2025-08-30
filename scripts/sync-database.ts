import axios from 'axios';
import * as fs from 'fs';

async function syncDatabase() {
  const specData = JSON.parse(fs.readFileSync('specs-data.json', 'utf-8'));
  
  // Get API URL from environment or use localhost for development
  const apiUrl = process.env.API_URL || 'http://localhost:3001';
  const syncApiKey = process.env.SYNC_API_KEY || 'development-key';
  
  try {
    // Batch update all specs
    const response = await axios.post(
      `${apiUrl}/api/specs/batch-sync`,
      specData,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${syncApiKey}`
        }
      }
    );
    
    console.log(`✅ Synced ${Object.keys(specData.specs).length} specs to database`);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error('❌ Database sync failed:', error.response?.data || error.message);
    } else {
      console.error('❌ Database sync failed:', error);
    }
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  syncDatabase()
    .then(() => process.exit(0))
    .catch(err => {
      console.error('❌ Database sync failed:', err);
      process.exit(1);
    });
}

export { syncDatabase };