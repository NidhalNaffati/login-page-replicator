import { test, expect, type Page } from '@playwright/test';

async function login(page: Page) {
  await page.getByPlaceholder('TNEEIN').fill('TNEEIN');
  await page.getByPlaceholder('••••••••').fill('4YOU');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await expect(page.getByText('My Tasks')).toBeVisible();
}

async function addTodo(page: Page, text: string) {
  await page.getByPlaceholder('Add a new task...').fill(text);
  await page.getByPlaceholder('Add a new task...').press('Enter');
}

test.describe('Todo App', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded', timeout: 15000 });
    await page.evaluate(() => {
      window.localStorage.clear();
    });
    await page.goto('/', { waitUntil: 'domcontentloaded', timeout: 15000 });
  });

  test('shows an error for invalid credentials', async ({ page }) => {
    await page.getByPlaceholder('TNEEIN').fill('wrong-user');
    await page.getByPlaceholder('••••••••').fill('wrong-pass');
    await page.getByRole('button', { name: 'Sign In' }).click();

    await expect(page.getByText('Invalid credentials. Try again.')).toBeVisible();
    await expect(page.getByText('Welcome back')).toBeVisible();
  });

  test('logs in successfully and shows the empty state', async ({ page }) => {
    await login(page);

    await expect(page.getByText('0 pending')).toBeVisible();
    await expect(page.getByText('No tasks found. Rest easy.')).toBeVisible();
  });

  test('allows logging out back to the login form', async ({ page }) => {
    await login(page);

    await page.getByRole('button', { name: 'Logout' }).click();

    await expect(page.getByText('Welcome back')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible();
  });

  test('keeps the authenticated session after reload', async ({ page }) => {
    await login(page);

    await page.reload({ waitUntil: 'domcontentloaded' });

    await expect(page.getByText('My Tasks')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Logout' })).toBeVisible();
  });

  test('keeps todos after reload', async ({ page }) => {
    await login(page);

    const todoText = `Persistent Todo ${Date.now()}`;
    await addTodo(page, todoText);

    await expect(page.getByText(todoText)).toBeVisible();
    await expect(page.getByText('1 pending')).toBeVisible();

    await page.reload({ waitUntil: 'domcontentloaded' });

    await expect(page.getByText(todoText)).toBeVisible();
    await expect(page.getByText('1 pending')).toBeVisible();
  });

  test('adds, completes, and deletes a todo', async ({ page }) => {
    await login(page);

    const todoText = `Test Todo ${Date.now()}`;
    await addTodo(page, todoText);

    const todoItem = page.getByText(todoText);
    await expect(todoItem).toBeVisible();
    await expect(page.getByText('1 pending')).toBeVisible();

    const todoRow = page.locator('.group', { has: page.getByText(todoText) });
    await todoRow.locator('button').first().click();

    const todoTextSpan = todoRow.locator('span', { hasText: todoText });
    await expect(todoTextSpan).toHaveClass(/line-through/);
    await expect(page.getByText('0 pending')).toBeVisible();

    await todoRow.hover();
    await todoRow.locator('button').nth(1).click();

    await expect(todoItem).not.toBeVisible();
    await expect(page.getByText('No tasks found. Rest easy.')).toBeVisible();
  });
});

