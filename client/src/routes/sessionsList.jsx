import { useEffect } from "react";
import { Form, useLoaderData, useNavigation, } from "react-router-dom";
import { getSessions } from "../sessions";

export async function loader({ request }) {
    const url = new URL(request.url);
    const searchQuery = url.searchParams.get("q") ?? "";
    const isSearch = (searchQuery == "") ? false : true;
    const sessions = isSearch ? await getSessions(searchQuery) : [];
    return { sessions, searchQuery, isSearch };
}

export default function SessionsList() {
    const { sessions, searchQuery, isSearch } = useLoaderData();
    const navigation = useNavigation();

    const searching =
        navigation.location &&
        new URLSearchParams(navigation.location.search).has(
            "q"
        );

    useEffect(() => {
        document.getElementById("q").value = searchQuery;
    }, [searchQuery]);

    return (
        <>
            <div id="searchbox">
                <div>
                    <Form id="search-form" role="search">
                        <input
                            id="q"
                            className={searching ? "loading" : ""}
                            aria-label="Search sessions"
                            placeholder="Search"
                            type="search"
                            name="q"
                            defaultValue={searchQuery}
                        />
                        <div id="search-spinner" aria-hidden hidden={!searching} />
                        <div className="sr-only" aria-live="polite"></div>
                        <button type="submit">Search</button>
                    </Form>
                </div>
            </div>
            <div id="sessions" className={navigation.state === "loading" ? "loading" : ""}>
                {sessions.length ? (
                    <ul>
                        {sessions.map((session) => (
                            <li key={session.id}>
                                <h2>{session.title} </h2>
                                <div>
                                    {session.abstract}
                                </div>
                            </li>
                        ))}
                    </ul>
                ) : (
                    <p>
                        <i>{isSearch ? "No session found" : "Use OpenAI to search for a session that will be interesting for you"}</i>
                    </p>
                )}
            </div>
        </>
    );
}