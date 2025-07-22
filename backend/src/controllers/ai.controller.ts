import type { Request, Response } from 'express';
import { getFinancialAnalysis } from '../utils/ai_service';

function formatDataForPrompt(data: any): string {
  // Convert complex objects to a simpler, readable string format
  return JSON.stringify(data, (key, value) => {
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      const simplified = { ...value };
      // Remove any large or unnecessary fields if they exist
      delete simplified.items;
      delete simplified.paymentHistory;
      return simplified;
    }
    return value;
  }, 2);
}

export const analyzeReport = async (req: Request, res: Response) => {
  const { businessId, reportType, filters, data } = req.body;

  if (!data) {
    return res.status(400).send({ message: 'Report data is required for analysis.' });
  }

  const dataString = formatDataForPrompt(data);

  const prompt = `
    As a professional business financial analyst for a small retail company, 
    please analyze the following financial data for a '${reportType}' report.
    The data is for business ID '${businessId}' with the following filters applied: ${JSON.stringify(filters)}.

    Financial Data:
    ${dataString}

    Based on this data, provide a concise analysis in JSON format. The JSON object should contain:
    1.  "trend": A one-word summary of the financial trend (e.g., "positive", "negative", "stable", "improving", "declining").
    2.  "recommendation": A single, actionable recommendation for the business owner to improve their financial standing. This should be a string, no more than two sentences.
    3.  "insights": An array of 2-3 key, insightful observations from the data. Each insight should be a short string.
    4.  "forecast": A simple JSON object with a key metric forecasted for the next period (e.g., {"nextMonthNetProfit": 2500.00} or {"nextMonthEquity": 15000.00}).

    Do not include any introductory text, explanations, or markdown formatting in your response. Only return the raw JSON object.
  `;

  try {
    const result = await getFinancialAnalysis(prompt);
    res.json(result);
  } catch (error) {
    console.error('AI analysis request failed:', error);
    res.status(500).send({ message: 'An error occurred while analyzing the report.' });
  }
}; 