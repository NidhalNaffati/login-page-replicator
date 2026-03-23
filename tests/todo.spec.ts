import { test, expect } from '@playwright/test';

test.describe('Todo App', () => {
  test.beforeEach(async ({ page }) => {
    // Go to the app
    await page.goto('http://localhost:8080');

    // Login if necessary
    // Check if login form is present
    const loginHeader = page.getByText('Welcome back');
    if (await loginHeader.isVisible()) {
      await page.fill('input[placeholder="TNEEIN"]', 'TNEEIN'); // using placeholder because input name/id not explicit
      await page.fill('input[placeholder="••••••••"]', '4YOU'); // using placeholder from Login.tsx

      // Wait for login to complete - maybe verify header is gone
      // The form does not have a submit button, it seems?
      // Wait, let me check Login.tsx again.
    }
  });

  test('should add, toggle, and delete a todo', async ({ page }) => {
    // We need to ensure we are logged in.
    // However, the Login component has an onLogin prop.
    // The submit action is triggered on form submit.
    // There is no submit button in Login.tsx!
    // Wait, let me re-read Login.tsx.

    // <form onSubmit={handleSubmit} className="space-y-4">
    // ... inputs ...
    // </form>
    // There is no explicit submit button.
    // So the user must press Enter in one of the inputs to submit the form.
    // I should simulate pressing Enter.

    const loginHeader = page.getByText('Welcome back');
    if (await loginHeader.isVisible()) {
      await page.fill('input[placeholder="TNEEIN"]', 'TNEEIN');
      await page.fill('input[placeholder="••••••••"]', '4YOU');
      await page.press('input[placeholder="••••••••"]', 'Enter');
    }

    // Assert we are on the dashboard
    await expect(page.getByText('My Tasks')).toBeVisible();

    const todoText = `Test Todo ${Date.now()}`;

    // Add Todo
    await page.fill('input[placeholder="Add a new task..."]', todoText);
    await page.press('input[placeholder="Add a new task..."]', 'Enter');

    // Verify Todo appears
    const todoItem = page.getByText(todoText);
    await expect(todoItem).toBeVisible();

    // Toggle Todo
    // The toggle button is the first button in the todo item container.
    // I can scope locator to the item text container.
    // The text element is a span. The parent div contains the buttons.
    const todoRow = page.locator('.group', { has: page.getByText(todoText) });

    // Find the toggle button (first button)
    const toggleButton = todoRow.locator('button').first();
    await toggleButton.click();

    // Verify it is completed (line-through class on the text span)
    const todoTextSpan = todoRow.locator('span', { hasText: todoText });
    await expect(todoTextSpan).toHaveClass(/line-through/);

    // Delete Todo
    // The delete button is the second button
    // It is shown on hover mostly (opacity-0 group-hover:opacity-100), but Playwright can click it even if hidden sometimes, or force click.
    // I should hover first to be safe and mimic user behavior.
    await todoRow.hover();
    const deleteButton = todoRow.locator('button').nth(1);
    await deleteButton.click();

    // Verify Todo is gone
    await expect(todoItem).not.toBeVisible();
  });
});

