// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import { install as installConfirmDialog } from "lib/confirm_dialog"
import "controllers"

installConfirmDialog(Turbo)
