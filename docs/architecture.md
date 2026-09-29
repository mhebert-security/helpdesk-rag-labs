# Architecture

The helpdesk assistant is a Python FastAPI web app that takes an employee
question, retrieves the most relevant chunks from an Azure AI Search index,
assembles a prompt, and returns a gpt-4o answer. An indexer populates the
index from documents held in blob storage. The full component diagram lives
in README.md under "Reference Architecture"; this file names each trust
boundary the labs harden in turn.

## Boundary A — Internet to App

Unauthenticated users and bots reach the App Service over HTTPS.

## Boundary B — App to Session

The orchestrator reads and writes session history in the session store.

## Boundary C — App to Index

The retriever queries the AI Search index and applies no per-user filter in v0.

## Boundary D — Unvetted docs to Index

The indexer ingests corpus documents, including canary files, into the index.

## Boundary E — Model to Tools/Plugins

The model may invoke tools or plugins the orchestrator exposes.

## Boundary F — Model output to Browser/Downstream

The model's answer flows back to the caller's browser or a downstream system.
