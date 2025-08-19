import threading

from flask import Flask, request, jsonify, render_template
from flask_restful import Api, Resource

from ollama import chat
from ollama import ChatResponse
from ollama import Client

from waitress import serve
app = Flask(__name__)
api = Api(app)


def pull_model(model_name="llama2"):
    c = Client()
    c.pull(model_name)
    print(f"Model '{model_name}' has been successfully pulled.")

class DeepThought(Resource):
    def get(self):
        model_name = "llama2:latest"

        client = Client()
        models = client.list().models  # Access the list of Model objects
        available_models = [m.model for m in models]

        print(f'Current model list: {client.list()}')
        print(f'Available models: {available_models}')
        if model_name in available_models:
            print(f"Model '{model_name}' is already pulled.")
        else:
            print(f"Model '{model_name}' is not pulled. Pulling it now...")

            threading.Thread(target=pull_model, args=(model_name,), daemon=True).start()
            return jsonify({'response': f"Model '{model_name}' is not pulled. Pulling it now in the background..."})

        question = request.args.get('question')
        if question is None:
            return jsonify({'error': 'No question provided'})
        else:
            # send the question to Ollama and get the answer
            # connect to Ollama and get the answer
            response: ChatResponse = chat(model='llama2', messages=[
                {
                    'role': 'user',
                    'content': question,
                },
            ])

            # or access fields directly from the response object
            print(response.message.content)

            return jsonify({'response': response.message.content})

class Api(Resource):
    def get(self):
        name = request.args.get('name')
        if name is None:
            return jsonify({'error': 'No name provided'})
        else:
            return jsonify({'hello': name})

@app.route('/')
def home():
    return render_template('ask_question.html')

@app.route('/api/', methods=['GET'])
def query_records():
    name = request.args.get('name')
    print(name)
    return jsonify({'hello': '' + name})


api.add_resource(DeepThought, '/ask')

api.add_resource(Api, '/api')


if __name__ == '__main__':
    serve(app, host="0.0.0.0", port=5001)