import { BaseConnector } from './base';
import { ValidationRequest, ValidationResult } from '../../types/validation';

const STATE_MAP: Record<string, string> = {
  AS: 'Aguascalientes',
  BC: 'Baja California',
  BS: 'Baja California Sur',
  CC: 'Campeche',
  CL: 'Coahuila',
  CM: 'Colima',
  CS: 'Chiapas',
  CH: 'Chihuahua',
  DF: 'Ciudad de México',
  DG: 'Durango',
  GT: 'Guanajuato',
  GR: 'Guerrero',
  HG: 'Hidalgo',
  JC: 'Jalisco',
  MC: 'Estado de México',
  MN: 'Michoacán',
  MS: 'Morelos',
  NT: 'Nayarit',
  NL: 'Nuevo León',
  OC: 'Oaxaca',
  PL: 'Puebla',
  QT: 'Querétaro',
  QR: 'Quintana Roo',
  SP: 'San Luis Potosí',
  SL: 'Sinaloa',
  SR: 'Sonora',
  TC: 'Tabasco',
  TS: 'Tamaulipas',
  TL: 'Tlaxcala',
  VZ: 'Veracruz',
  YN: 'Yucatán',
  ZS: 'Zacatecas',
  NE: 'Nacido en el Extranjero',
};

function parseCurp(curpInput: string): {
  dateOfBirth: string;
  sexMarker: string;
  placeOfBirth: string;
} | null {
  const curp = curpInput.toUpperCase();
  const regex = /^([A-Z][AEIOUX][A-Z]{2})(\d{2})(\d{2})(\d{2})([HM])([A-Z]{2})[A-Z]{3}[A-Z\d]\d$/;
  const match = curp.match(regex);

  if (!match) return null;

  const yearYY = Number.parseInt(match[2], 10);
  const currentYearYY = new Date().getUTCFullYear() % 100;
  const fullYear = yearYY > currentYearYY ? 1900 + yearYY : 2000 + yearYY;

  return {
    dateOfBirth: `${fullYear}-${match[3]}-${match[4]}`,
    sexMarker: match[5] === 'H' ? 'HOMBRE' : 'MUJER',
    placeOfBirth: STATE_MAP[match[6]] ?? match[6],
  };
}

export class CurpConnector extends BaseConnector {
  constructor() {
    super('mock-curp-connector', 'CURP');
  }

  async validate(input: ValidationRequest): Promise<ValidationResult> {
    const rawCurp = input.claimedData.curp;
    const curp = typeof rawCurp === 'string' ? rawCurp.toUpperCase().trim() : '';
    const parsed = parseCurp(curp);

    if (!parsed) {
      return {
        domain: 'CURP',
        overallResult: 'rejected',
        fieldResults: [
          { field: 'curp', result: 'mismatch', confidence: 'high' },
          { field: 'full_name', result: 'not_checked', confidence: 'low' },
          { field: 'date_of_birth', result: 'not_checked', confidence: 'low' },
        ],
        sourceType: 'government_validated',
        sourceName: this.name,
        evidenceRefs: [],
        validatedAt: this.nowIso(),
      };
    }

    return {
      domain: 'CURP',
      overallResult: 'verified',
      fieldResults: [
        { field: 'curp', result: 'verified', confidence: 'high' },
        { field: 'date_of_birth', result: 'verified', confidence: 'high' },
        { field: 'sex_marker', result: 'verified', confidence: 'medium' },
        { field: 'place_of_birth', result: 'verified', confidence: 'medium' },
        { field: 'full_name', result: 'not_found', confidence: 'low' },
      ],
      sourceType: 'government_validated',
      sourceName: this.name,
      evidenceRefs: [`curp:${curp}`, `dob:${parsed.dateOfBirth}`],
      validatedAt: this.nowIso(),
      expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
    };
  }
}

export class RfcConnector extends BaseConnector {
  constructor() {
    super('mock-rfc-connector', 'RFC');
  }

  async validate(input: ValidationRequest): Promise<ValidationResult> {
    const rawRfc = input.claimedData.rfc;
    const rfc = typeof rawRfc === 'string' ? rawRfc.toUpperCase().trim() : '';
    const regex = /^[A-Z&Ñ]{3,4}\d{6}[A-Z0-9]{3}$/;
    const ok = regex.test(rfc);

    return {
      domain: 'RFC',
      overallResult: ok ? 'partial_match' : 'rejected',
      fieldResults: [
        { field: 'rfc', result: ok ? 'verified' : 'mismatch', confidence: 'high' },
        { field: 'person_linkage', result: 'not_checked', confidence: 'low' },
      ],
      sourceType: 'government_validated',
      sourceName: this.name,
      evidenceRefs: ok ? [`rfc:${rfc}`] : [],
      validatedAt: this.nowIso(),
    };
  }
}

export class BiometricDocumentConnector extends BaseConnector {
  constructor(domain: 'INE' | 'PASSPORT') {
    super(`mock-${domain.toLowerCase()}-doc-biometric-connector`, domain);
  }

  async validate(input: ValidationRequest): Promise<ValidationResult> {
    const hasDoc = Boolean(input.linkedDocuments?.length);
    const hasSelfie = Boolean(input.biometricEvidence?.selfieRef);
    const hasLiveness = Boolean(input.biometricEvidence?.livenessRef);

    const overallResult = hasDoc && hasSelfie && hasLiveness ? 'verified' : 'pending_review';

    return {
      domain: this.domain,
      overallResult,
      fieldResults: [
        { field: 'document_authenticity', result: hasDoc ? 'verified' : 'not_found', confidence: hasDoc ? 'medium' : 'low' },
        { field: 'face_match', result: hasSelfie ? 'verified' : 'not_found', confidence: hasSelfie ? 'medium' : 'low' },
        { field: 'liveness', result: hasLiveness ? 'verified' : 'not_found', confidence: hasLiveness ? 'high' : 'low' },
      ],
      sourceType: 'document_verified',
      sourceName: this.name,
      evidenceRefs: [
        ...(input.linkedDocuments ?? []).map((item) => item.fileRef),
        ...(hasSelfie ? [input.biometricEvidence!.selfieRef!] : []),
        ...(hasLiveness ? [input.biometricEvidence!.livenessRef!] : []),
      ],
      validatedAt: this.nowIso(),
    };
  }
}

export function getMexicoConnectors() {
  return [
    new CurpConnector(),
    new RfcConnector(),
    new BiometricDocumentConnector('INE'),
    new BiometricDocumentConnector('PASSPORT'),
  ];
}
