import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const port = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'government-validation-orchestrator' });
});

// Basic CURP parsing function
const STATE_MAP: Record<string, string> = {
  AS: 'Aguascalientes', BC: 'Baja California', BS: 'Baja California Sur',
  CC: 'Campeche', CL: 'Coahuila', CM: 'Colima', CS: 'Chiapas',
  CH: 'Chihuahua', DF: 'Ciudad de México', DG: 'Durango', GT: 'Guanajuato',
  GR: 'Guerrero', HG: 'Hidalgo', JC: 'Jalisco', MC: 'Estado de México',
  MN: 'Michoacán', MS: 'Morelos', NT: 'Nayarit', NL: 'Nuevo León',
  OC: 'Oaxaca', PL: 'Puebla', QT: 'Querétaro', QR: 'Quintana Roo',
  SP: 'San Luis Potosí', SL: 'Sinaloa', SR: 'Sonora', TC: 'Tabasco',
  TS: 'Tamaulipas', TL: 'Tlaxcala', VZ: 'Veracruz', YN: 'Yucatán',
  ZS: 'Zacatecas', NE: 'Nacido en el Extranjero'
};

function parseCurp(curp: string) {
  const regex = /^([A-Z][AEIOUX][A-Z]{2})(\d{2})(\d{2})(\d{2})([HM])([A-Z]{2})[A-Z]{3}[A-Z\d]\d$/;
  const match = curp.toUpperCase().match(regex);
  if (!match) return null;

  const [_, initials, yy, mm, dd, gender, stateCode] = match;
  
  // Year calculation (naive heuristic: if > current year, assume 19XX, else 20XX)
  const currentYear = new Date().getFullYear() % 100;
  const yearObj = parseInt(yy, 10);
  const fullYear = yearObj > currentYear ? 1900 + yearObj : 2000 + yearObj;
  
  return {
    initials,
    dateOfBirth: `${fullYear}-${mm}-${dd}`,
    sexMarker: gender === 'H' ? 'Hombre' : 'Mujer',
    stateCode: STATE_MAP[stateCode] || stateCode,
  };
}

app.post('/api/validate/curp', (req, res) => {
  const { curp } = req.body;
  if (!curp || typeof curp !== 'string') {
    return res.status(400).json({ error: 'Missing or invalid CURP' });
  }

  const cleanCurp = curp.toUpperCase().trim();
  if (cleanCurp.length !== 18) {
     return res.status(400).json({ error: 'CURP must be 18 characters' });
  }

  const parsed = parseCurp(cleanCurp);
  
  if (!parsed) {
     return res.status(400).json({ error: 'Invalid CURP format. Failed government validation checks.' });
  }

  // Simulate government API delay
  setTimeout(() => {
    const validationResult = {
      overallResult: 'validated',
      assuranceLevel: 'IAL1',
      profile: {
         canonical_curp: cleanCurp,
         canonical_date_of_birth: parsed.dateOfBirth,
         canonical_sex_marker: parsed.sexMarker,
         canonical_state_of_birth: parsed.stateCode,
         // Note: Without an active RENAPO/Government API key, we cannot query the exact full name.
         // We reverse-engineer the initials to demonstrate the extraction capability.
         canonical_full_name: `(Requires Gov API Key) - Initials: ${parsed.initials}`,
      },
      validation_domain: 'CURP',
      sourceType: 'dummy_government_mock'
    };
    
    res.json({ success: true, result: validationResult });
  }, 1200);
});

app.listen(port, () => {
  console.log(`Backend Orchestrator listening on port ${port}`);
});
