import { useEffect } from "react";
import { Form, useLoaderData, useNavigation, } from "react-router-dom";
import { getSessions } from "../sessions";

export async function loader({ request }) {
    const url = new URL(request.url);
    const searchQuery = url.searchParams.get("q") ?? "";
    var isSearch = (searchQuery == "") ? false : true;
    var { sessions, errorInfo } = isSearch ? await getSessions(searchQuery) : {sessions:[], errorInfo:null};
    if (!Array.isArray(sessions)) { 
        errorInfo = { errorMessage: "Error: sessions is not an array" };
        sessions = [];
    }
    return { sessions, searchQuery, isSearch, errorInfo };
}

export default function SessionsList() {
    const { sessions, searchQuery, isSearch, errorInfo } = useLoaderData();
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
                {errorInfo ? <p id="error"><i>{"[Error] Status: " + errorInfo.errorCode + " Message: " + errorInfo.errorMessage}</i></p> : ""}
                {sessions.length ? (
                    <section className="agenda-group">
                        {sessions.map((session) => (
                            <div>
                                <p className="font-title-2"><a href={"#" + session.id}>{session.title}</a></p>
                                <p className="session-similarity font-stronger">Similarity: {session.cosine_similarity.toFixed(6)}</p>
                                <p className="font-subtitle-2 abstract">
                                    {session.abstract}
                                </p>
                            </div>
                        ))}
                    </section>
                ) : (
                    <p>
                        <i><center>
                            { isSearch ? "No session found" : "" }
                        </center></i>
                    </p>
                )}
            </div>
        </>
    );
}