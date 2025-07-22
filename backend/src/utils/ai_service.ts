import { GoogleGenerativeAI } from "@google/generative-ai";

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
  throw new Error("GEMINI_API_KEY is not set in environment variables.");
}

const genAI = new GoogleGenerativeAI(apiKey);

const model = genAI.getGenerativeModel({
  model: "gemini-1.5-flash",
});

export async function getFinancialAnalysis(prompt: string): Promise<any> {
  try {
    const result = await model.generateContent(prompt);
    const responseText = await result.response.text();
    return JSON.parse(responseText);
  } catch (error) {
    console.error("Error getting financial analysis from Gemini:", error);
    throw new Error("Failed to get analysis from AI service.");
  }
} 