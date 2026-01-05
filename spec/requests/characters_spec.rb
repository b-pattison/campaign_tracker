require 'rails_helper'

RSpec.describe "Characters", type: :request do
    describe "GET /characters" do
        it "returns characters" do
            create(:character, name: "Finch")
            create(:character, name: "Vulture", pc: false)

            get "/characters"

            expect(response).to have_http_status(:ok)
            expect(json.size).to eq(2)
            expect(json.map { |chara| chara["name"]}).to include("Finch", "Vulture")
        end
    end

    describe "GET /characters/:id" do
        it "returns the character" do
            character = create(:character, name: "Finch")

            get "/characters/#{character.id}"

            expect(response).to have_http_status(:ok)
            expect(json["name"]).to eq("Finch")
            expect(json["id"]).to eq(character.id)
        end

        it "returns 404 if character is not found" do
            get "/characters/999"

            expect(response).to have_http_status(:not_found)
        end
    end
    describe "POST /characters" do
        it "create a new  character" do
            campaign = create(:campaign)
            payload = {
                character: { name: "Carter", pc: true, level: 4, class_name: "Rogue", campaign_id: campaign.id }
            }

            expect {
                post "/characters", params: payload
            }.to change(Character, :count).by(1)

            expect(response).to have_http_status(:created)
            expect(json["name"]).to eq("Carter")
            expect(json["pc"]).to eq(true)
            expect(json["level"]).to eq(4)
            expect(json["class_name"]).to eq("Rogue")
        end

        it "returns 422 if the character is invalid" do
            payload = {
                character: { name: "", pc: true, level: 4, class_name: "Rogue" }
            }

            post "/characters", params: payload
            
            expect(response).to have_http_status(:unprocessable_content)
            expect(json["errors"]).to be_present
        end
    end

    describe "PATCH /characters/:id" do
        it "updates the character" do
            character = create(:character, name: "Finch", level: 6, pc: true, class_name: "Wizard")
            patch "/characters/#{character.id}", params: {
                character: {level: 7}
            }

            expect(response).to have_http_status(:ok)
            expect(json["level"]).to eq(7)
            expect(character.reload.level).to eq(7)
        end

        it "returns 422 for invalid updates" do
            character = create(:character, name: "Finch", level: 6, pc: true, class_name: "Wizard")
            patch "/characters/#{character.id}", params: {
                character: {level: 21}
            }

            expect(response).to have_http_status(:unprocessable_content)
            expect(json["errors"]).to be_present
        end
    end

    describe "DELETE /characters/:id" do
        it "deletes the character" do
            character = create(:character, name: "Finch")
            expect {
                delete "/characters/#{character.id}"
        }.to change(Character, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(Character.find_by(id: character.id)).to be_nil
        end
    end
end
