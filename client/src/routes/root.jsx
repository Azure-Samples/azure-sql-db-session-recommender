import { useLoaderData, Outlet } from "react-router-dom";
import { getSessionsCount } from "../sessions";

export async function loader() {
  const sessionsCount = await getSessionsCount();
  return { sessionsCount };
}

export default function Root() {
  const { sessionsCount } = useLoaderData();

  return (
    <>
      <div id="header">
        <h1 className="font-title-2"><a href="https://www.dotnetconf.net/">.NET Conf 2023</a> Session Finder</h1>
        <p className="font-subtitle-2">
          Use OpenAI to search for interesting sessions. Write the topic you're interested in, and (up to) the top ten most interesting and related session will be returned.         
          The search is done using <a href="https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#embeddings-models">text embeddings</a> and then using <a href="https://en.wikipedia.org/wiki/Cosine_similarity" target="_blank">cosine similarity</a> to find the most similar sessions.
        </p>
        <p className="font-subtitle-2">There are {sessionsCount} sessions indexed so far.</p>
      </div>
      <div>      
        <Outlet /> 
      </div>
    </>
  );
}