# Glossary

**RAG (Retrieval-Augmented Generation).** A pattern that fetches relevant
documents and hands them to a model so the answer is grounded in those
documents rather than in the model's training data.

**LLM (Large Language Model).** The model that turns text into text and
answers questions.

**Vector embedding.** A list of numbers that captures the meaning of a piece
of text, so similar text gets similar numbers.

**Hybrid search.** Retrieval that combines keyword matching with vector
similarity and merges the results.

**ACL (Access Control List).** The per-user or per-role rules that say who can
read which document.

**APIM (Azure API Management).** The gateway that fronts an API with rate
limits, policies, and a web application firewall.

**Managed Identity.** An identity Azure issues to a resource so it can reach
other services without a stored key or password.

**Canary token.** A synthetic secret planted in a document; its appearance in
output proves the document was read and surfaced.

**Groundedness.** A measure of whether a model answer is supported by the
provided context rather than invented.

**Jailbreak.** A prompt that convinces a model to ignore its safety rules.

**Indirect injection.** Instructions hidden inside retrieved data that steer
the model, distinct from instructions the user types directly.
