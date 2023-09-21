import { Form, useLoaderData } from "react-router-dom";
import { getSessions } from "../sessions";

export async function loader({ request }) {
    const url = new URL(request.url);
    const q = url.searchParams.get("q");

    const sessions = await getSessions(q);
    return { sessions };
}

export default function Root() {
    const { sessions } = useLoaderData();
    return (
      <>
          <div>
            <h1>Airlift Session Finder</h1>            
            <Form id="search-form" role="search">
              <input
                id="q"
                aria-label="Search contacts"
                placeholder="Search"
                type="search"
                name="q"
              />            
              <button type="submit">Search</button>
            </Form>
          </div>
          <nav>
          {sessions.length ? (
            <ul>
              {sessions.map((session) => (
                <li key={session.id}>
                    <h2>{ session.title } </h2>
                    <div>
                      { session.abstract }
                    </div>
                </li>
              ))}
            </ul>
          ) : (
            <p>
              <i>No sessions found</i>
            </p>
          )}
          </nav>
      </>
    );
  }