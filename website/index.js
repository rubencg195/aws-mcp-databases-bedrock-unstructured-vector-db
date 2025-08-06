document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('queryForm');
    const responseDiv = document.getElementById('response');

    form.addEventListener('submit', function(e) {
        e.preventDefault();
        
        const query = document.getElementById('query').value;
        const context = document.getElementById('context').value;
        
        if (!query.trim()) {
            alert('Please enter a query');
            return;
        }
        
        // Show loading state
        responseDiv.innerHTML = '<p>Processing your query...</p>';
        
        // Here you would typically make an API call to your backend
        // For now, we'll just show a placeholder response
        setTimeout(() => {
            responseDiv.innerHTML = `
                <h3>Response:</h3>
                <p><strong>Query:</strong> ${query}</p>
                <p><strong>Context:</strong> ${context || 'No context provided'}</p>
                <p><em>This is a placeholder response. In a real implementation, this would be the response from your knowledge base.</em></p>
            `;
        }, 1000);
    });
});
