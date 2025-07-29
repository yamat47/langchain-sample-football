import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    console.log("BookAssistant controller connected")
    console.log("Input target:", this.hasInputTarget)
    console.log("Submit target:", this.hasSubmitTarget)
    this.enableForm()
  }

  initialize() {
    console.log("BookAssistant controller initialized")
  }

  submit(event) {
    console.log("Form submit event triggered")
    
    if (!this.hasInputTarget || !this.hasSubmitTarget) {
      console.error("Missing targets")
      return
    }
    
    const message = this.inputTarget.value
    console.log("Message value:", message)
    
    if (message.trim() !== "") {
      this.inputTarget.value = ""
      this.disableForm()
    }
  }

  disableForm() {
    console.log("Disabling form")
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Sending..."
    this.submitTarget.style.opacity = "0.6"
    this.submitTarget.style.cursor = "not-allowed"
    this.inputTarget.disabled = true
  }

  enableForm() {
    console.log("Enabling form")
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.textContent = "Send"
      this.submitTarget.style.opacity = "1"
      this.submitTarget.style.cursor = "pointer"
    }
    if (this.hasInputTarget) {
      this.inputTarget.disabled = false
      this.inputTarget.focus()
    }
  }

  turboStreamConnect(event) {
    console.log("Turbo stream connect event")
    setTimeout(() => {
      this.enableForm()
    }, 100)
  }
}