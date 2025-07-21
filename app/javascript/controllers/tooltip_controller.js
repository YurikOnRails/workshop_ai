import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    text: String
  }

  connect() {
    // The tooltip is already in the HTML, we just need to position it
    this.tooltip = this.element.querySelector('.tooltip')
    
    // Position the tooltip on connect
    this.positionTooltip()
    
    // Re-position on window resize
    window.addEventListener('resize', this.positionTooltip.bind(this))
  }
  
  disconnect() {
    // Clean up event listener
    window.removeEventListener('resize', this.positionTooltip.bind(this))
  }
  
  positionTooltip() {
    if (!this.tooltip) return
    
    const rect = this.element.getBoundingClientRect()
    const tooltipRect = this.tooltip.getBoundingClientRect()
    
    // Center the tooltip above the element
    const left = rect.left + (rect.width / 2) - (tooltipRect.width / 2)
    const top = rect.top - tooltipRect.height - 8 // 8px offset from element
    
    // Ensure the tooltip stays within the viewport
    const adjustedLeft = Math.max(8, Math.min(window.innerWidth - tooltipRect.width - 8, left))
    
    this.tooltip.style.left = `${adjustedLeft}px`
    this.tooltip.style.top = `${Math.max(8, top)}px`
  }
  
  show() {
    if (this.tooltip) {
      this.tooltip.classList.remove('opacity-0', 'invisible')
      this.tooltip.classList.add('opacity-100', 'visible')
    }
  }
  
  hide() {
    if (this.tooltip) {
      this.tooltip.classList.add('opacity-0', 'invisible')
      this.tooltip.classList.remove('opacity-100', 'visible')
    }
  }
}
