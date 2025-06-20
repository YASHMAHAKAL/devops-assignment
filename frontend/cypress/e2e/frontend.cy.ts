describe('Frontend Homepage', () => {
  it('displays message from backend', () => {
    cy.visit('http://localhost:3000');
    cy.contains('Frontend (Next.js)');
    cy.contains('Message from Backend:');
    cy.get('p').should('not.be.empty');
  });
});
