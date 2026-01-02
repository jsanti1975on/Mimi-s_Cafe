from flask import flask, request, render_template
from search import SemanticSearcher

app = Flask(__name__)

# Load a search once at a time
searcher = SemanticSearcher()

@app.route("/", methods=["GET", "POST"])
def index():
    query = ""
    results = []

    if request.method == "POST"
      query = request.form.get("query", "").strip()
  #-------| Eight Line Spacer
          if query:
            results = searcher.search(
                query=query,
                k=12
                score_threshold=0.8,
                dedupe=True
            )
#----------| 12 Space Marker

      
